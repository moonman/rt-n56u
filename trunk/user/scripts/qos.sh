#!/bin/sh

# qos-script v2.00

## Please modify user configuration in /etc/qos.conf

# User configuration
[ -f /etc/storage/qos.conf ] && . /etc/storage/qos.conf

# If no interface defined, use WAN interface
[ "$QOS_IF" ] || QOS_IF=$(nvram get wan_ifname)

if [ "$QOS_ENABLED" = "YES" ]; then
  # Length of burst buffers in ms (must be larger than kernel jiffy of 10ms)
  DBURST_D=10
  DBURST_U=10

  MTU=1500

  # Minimum class rate as percentage of full line rate
  MIN_RATE=10

  modprobe cls_fw >&- 2>&-
  modprobe sch_htb >&- 2>&-
  modprobe sch_sfq >&- 2>&-
  modprobe sch_red >&- 2>&-
  modprobe xt_length >&- 2>&-
  modprobe imq numdevs=1 >&- 2>&-
  modprobe xt_IMQ >&- 2>&-
  modprobe ipt_ipp2p >&- 2>&-
  # modprobe xt_layer7 >&- 2>&-
  modprobe xt_dscp >&- 2>&-
  modprobe xt_DSCP >&- 2>&-
  modprobe sch_red >&- 2>&-

  iptables -t mangle -F
  iptables -t mangle -X

  # Set up the InterMediate Queuing device (IMQ)
  ip link set imq0 up

  # Remove queuing disciplines from all interfaces
  sed -n 's/ *\(.*\):.*/\1/p' /proc/net/dev | while read INTERFACE; do
    tc qdisc del dev $INTERFACE root >&- 2>&-
  done

  [ $UPLOAD -ne 0 ] && {
    # Calculate buffer lengths in bytes
    BURST_U=$(($DBURST_U*$UPLOAD/8))
  
    # Make sure burst buffer size is at least MTU
    [ $BURST_U -lt $((1*$MTU)) ] && BURST_U=$((1*$MTU))

    # Calculate r2q for htb discipline
    RTOQ_U=$(($MIN_RATE*$UPLOAD*10/(8*$MTU)))
    [ $RTOQ_U -gt 20 ] && RTOQ_U=20
    [ $RTOQ_U -eq 0 ] && RTOQ_U=1

    # Attach egress queuing discipline to QoS interface
    tc qdisc add dev $QOS_IF root handle 1: htb default 40 r2q $RTOQ_U
    tc class add dev $QOS_IF parent 1: classid 1:1 htb rate ${UPLOAD}kbit ceil ${UPLOAD}kbit burst $(($BURST_U*3)) cburst $(($BURST_U*3)) mtu $MTU
    tc class add dev $QOS_IF parent 1:1 classid 1:10 htb rate $(($UPLOAD*5/10))kbit ceil ${UPLOAD}kbit burst $(($BURST_U*1)) cburst $(($BURST_U*1)) prio 1 mtu $MTU
    tc class add dev $QOS_IF parent 1:1 classid 1:20 htb rate $(($UPLOAD*2/10))kbit ceil ${UPLOAD}kbit burst $(($BURST_U*1)) cburst $(($BURST_U*1)) prio 2 mtu $MTU
    tc class add dev $QOS_IF parent 1:1 classid 1:30 htb rate $(($UPLOAD*2/10))kbit ceil ${UPLOAD}kbit burst $(($BURST_U*1)) cburst $(($BURST_U*1)) prio 3 mtu $MTU
    tc class add dev $QOS_IF parent 1:1 classid 1:40 htb rate $(($UPLOAD*1/10))kbit ceil ${UPLOAD}kbit burst $(($BURST_U*1)) cburst $(($BURST_U*1)) prio 4 mtu $MTU

    tc qdisc add dev $QOS_IF parent 1:10 sfq quantum $MTU perturb 10
    tc qdisc add dev $QOS_IF parent 1:20 sfq quantum $MTU perturb 10
    tc qdisc add dev $QOS_IF parent 1:30 sfq quantum $MTU perturb 10
    tc qdisc add dev $QOS_IF parent 1:40 sfq quantum $MTU perturb 10

    tc filter add dev $QOS_IF parent 1: prio 1 protocol ip handle 1 fw flowid 1:10
    tc filter add dev $QOS_IF parent 1: prio 2 protocol ip handle 2 fw flowid 1:20
    tc filter add dev $QOS_IF parent 1: prio 3 protocol ip handle 3 fw flowid 1:30
    tc filter add dev $QOS_IF parent 1: prio 4 protocol ip handle 4 fw flowid 1:40
  }

  [ $DOWNLOAD -ne 0 ] && {
    # Calculate buffer lengths in bytes
    BURST_D=$(($DBURST_D*$DOWNLOAD/8))
  
    # Make sure burst buffer size is at least MTU
    [ $BURST_D -lt $((1*$MTU)) ] && BURST_D=$((1*$MTU))

    # Calculate r2q for htb discipline
    RTOQ_D=$(($MIN_RATE*$DOWNLOAD*10/(8*$MTU)))
    [ $RTOQ_D -gt 20 ] && RTOQ_D=20
    [ $RTOQ_D -eq 0 ] && RTOQ_D=1

    # Attach ingress queuing discipline to IMQ interface
    # htb qdisc without default: all unmarked (mark 0) packages pass unlimited
    # htb with non-existing default: unmarked packages get dropped
    tc qdisc add dev imq0 root handle 1: htb default 40 r2q $RTOQ_D
    tc class add dev imq0 parent 1: classid 1:1 htb rate ${DOWNLOAD}kbit ceil ${DOWNLOAD}kbit burst $((BURST_D*3)) cburst $((BURST_D*3)) mtu $MTU
    tc class add dev imq0 parent 1:1 classid 1:10 htb rate $(($DOWNLOAD*5/10))kbit ceil ${DOWNLOAD}kbit burst $((BURST_D*1)) cburst $((BURST_D*1)) prio 1 mtu $MTU
    tc class add dev imq0 parent 1:1 classid 1:20 htb rate $(($DOWNLOAD*2/10))kbit ceil ${DOWNLOAD}kbit burst $((BURST_D*1)) cburst $((BURST_D*1)) prio 2 mtu $MTU
    tc class add dev imq0 parent 1:1 classid 1:30 htb rate $(($DOWNLOAD*2/10))kbit ceil ${DOWNLOAD}kbit burst $((BURST_D*1)) cburst $((BURST_D*1)) prio 3 mtu $MTU
    tc class add dev imq0 parent 1:1 classid 1:40 htb rate $(($DOWNLOAD*1/10))kbit ceil $(($DOWNLOAD*3/4))kbit burst $((BURST_D*1)) cburst $((BURST_D*1)) prio 4 mtu $MTU

    tc qdisc add dev imq0 parent 1:10 red limit $((40*$MTU)) min $((5*$MTU)) max $((20*$MTU)) avpkt $(($MTU*6/10)) burst 16 probability 0.015
    tc qdisc add dev imq0 parent 1:20 red limit $((40*$MTU)) min $((5*$MTU)) max $((20*$MTU)) avpkt $(($MTU*6/10)) burst 16 probability 0.015
    tc qdisc add dev imq0 parent 1:30 red limit $((40*$MTU)) min $((5*$MTU)) max $((20*$MTU)) avpkt $(($MTU*6/10)) burst 16 probability 0.015
    tc qdisc add dev imq0 parent 1:40 red limit $((40*$MTU)) min $((5*$MTU)) max $((20*$MTU)) avpkt $(($MTU*6/10)) burst 16 probability 0.015

    tc filter add dev imq0 parent 1: prio 1 protocol ip handle 1 fw flowid 1:10
    tc filter add dev imq0 parent 1: prio 2 protocol ip handle 2 fw flowid 1:20
    tc filter add dev imq0 parent 1: prio 3 protocol ip handle 3 fw flowid 1:30
    tc filter add dev imq0 parent 1: prio 4 protocol ip handle 4 fw flowid 1:40
  }

  iptables -t mangle -N mark_chain
  iptables -t mangle -N egress_chain
  iptables -t mangle -N ingress_chain

  # Set up egress marking chain
  iptables -t mangle -A POSTROUTING -o $QOS_IF -j egress_chain

  # Mark ingress in FORWARD and INPUT chains to make sure any DNAT (virt. server) is taken into account
  # Mark ingress in FORWARD chain for LAN and send through the IMQ device
  iptables -t mangle -A FORWARD -i $QOS_IF -j ingress_chain
  iptables -t mangle -A FORWARD -i $QOS_IF -j IMQ --todev 0

  # Mark ingress in INPUT chain for this router and send through the IMQ device
  iptables -t mangle -A INPUT -i $QOS_IF -j ingress_chain
  iptables -t mangle -A INPUT -i $QOS_IF -j IMQ --todev 0

  #################################### FUNCTION DEFINITIONS ############################################
  mark_addr_in()
    {
     # Set up ingress rules based on ip_address[:port[:range]]
     # $1 is a list of ip:port elements
     # $2 is the priority

     for ADDR in $1; do
       IP_PART=`echo $ADDR | sed -n 's/\([^:]*\):.*/\1/p'`
       if [ "$IP_PART" ]; then
         PORT_PART=`echo $ADDR | sed -n 's/[^:]*:\(.*\)/\1/p'`
         iptables -t mangle -A ingress_chain -d $IP_PART -p tcp --dport $PORT_PART -j MARK --set-mark $2
         iptables -t mangle -A ingress_chain -d $IP_PART -p udp --dport $PORT_PART -j MARK --set-mark $2
       else
         iptables -t mangle -A ingress_chain -d $ADDR -j MARK --set-mark $2
       fi
     done
    }

  mark_addr_out()
    {
     # Set up egress rules based on ip_address[:port[:range]]
     # $1 is a list of ip:port elements
     # $2 is the priority

     for ADDR in $1; do
       IP_PART=`echo $ADDR | sed -n 's/\([^:]*\):.*/\1/p'`
       if [ "$IP_PART" ]; then
         PORT_PART=`echo $ADDR | sed -n 's/[^:]*:\(.*\)/\1/p'`
         iptables -t mangle -A egress_chain -s $IP_PART -p tcp --dport $PORT_PART -j MARK --set-mark $2
         iptables -t mangle -A egress_chain -s $IP_PART -p udp --dport $PORT_PART -j MARK --set-mark $2
       else
         iptables -t mangle -A egress_chain -s $ADDR -j MARK --set-mark $2
       fi
     done
    }
  ######################################################################################################

  ###################################### MARK CHAIN ####################################################
  # Restore any saved connection mark if not already marked
  iptables -t mangle -A mark_chain -m mark --mark 0 -j CONNMARK --restore-mark

  # Mark expr packets based on port numbers and protocol
  for PORT in $UDP_EXPR; do
    iptables -t mangle -A mark_chain -m mark --mark 0 -p udp --dport $PORT -j MARK --set-mark 1
  done
  for PORT in $TCP_EXPR; do
    iptables -t mangle -A mark_chain -m mark --mark 0 -p tcp --dport $PORT -j MARK --set-mark 1
  done

  # Mark prio packets based on port numbers and protocol
  for PORT in $UDP_PRIO; do
    iptables -t mangle -A mark_chain -m mark --mark 0 -p udp --dport $PORT -j MARK --set-mark 2
  done
  for PORT in $TCP_PRIO; do
    iptables -t mangle -A mark_chain -m mark --mark 0 -p tcp --dport $PORT -j MARK --set-mark 2
  done

  # Mark bulk packets based on port numbers and protocol
  for PORT in $UDP_BULK; do
    iptables -t mangle -A mark_chain -m mark --mark 0 -p udp --dport $PORT -j MARK --set-mark 4
  done
  for PORT in $TCP_BULK; do
    iptables -t mangle -A mark_chain -m mark --mark 0 -p tcp --dport $PORT -j MARK --set-mark 4
  done

  # Default is normal priority (to make sure every packet on WAN interface gets marked)
  iptables -t mangle -A mark_chain -m mark --mark 0 -j MARK --set-mark 3

  # Save mark onto connection
  iptables -t mangle -A mark_chain -j CONNMARK --save-mark

  # ICMP gets high priority (impress friends)
  iptables -t mangle -A mark_chain -p icmp -j MARK --set-mark 1
  iptables -t mangle -A mark_chain -p ipv6-icmp -j MARK --set-mark 1

  # Small UDP packets (most likely games) get high priority
  [ "$UDP_LENGTH" -gt 0 ] && iptables -t mangle -A mark_chain -p udp -m length --length :$UDP_LENGTH -j MARK --set-mark 1

  # Small TCP packets get high priority
  if [ "$TCP_LENGTH" -gt 0 ]; then
    for PORT in $TCP_LENGTH_PORTS; do
      iptables -t mangle -A mark_chain -p tcp --dport $PORT -m length --length :$TCP_LENGTH -j MARK --set-mark 1
    done
  fi
  ######################################################################################################

  ###################################### INGRESS CHAIN #################################################
  # Mark bulk packets based on destination LAN ip address and port number
  mark_addr_in "$IP_BULK" 4

  # Mark prio packets based on destination LAN ip address and port number
  mark_addr_in "$IP_PRIO" 2

  # Mark expr packets based on destination LAN ip address and port number
  mark_addr_in "$IP_EXPR" 1

  # Call mark_chain
  iptables -t mangle -A ingress_chain -j mark_chain
  ######################################################################################################
  
  ######################################## EGRESS CHAIN ################################################
  # Mark bulk packets based on tos match (egress only)
  for PROTO in $TOS_BULK; do
    iptables -t mangle -A egress_chain -m tos --tos $PROTO -j MARK --set-mark 4
  done

  # Mark prio packets based on tos match (egress only)
  for PROTO in $TOS_PRIO; do
    iptables -t mangle -A egress_chain -m tos --tos $PROTO -j MARK --set-mark 2
  done

  # Mark expr packets based on tos match (egress only)
  for PROTO in $TOS_EXPR; do
    iptables -t mangle -A egress_chain -m tos --tos $PROTO -j MARK --set-mark 1
  done

  # Mark bulk packets based on dscp match (egress only)
  for PROTO in $DSCP_BULK; do
    iptables -t mangle -A egress_chain -m dscp --dscp $PROTO -j MARK --set-mark 4
  done

  # Mark prio packets based on dscp match (egress only)
  for PROTO in $DSCP_PRIO; do
    iptables -t mangle -A egress_chain -m dscp --dscp $PROTO -j MARK --set-mark 2
  done

  # Mark expr packets based on dscp match (egress only)
  for PROTO in $DSCP_EXPR; do
    iptables -t mangle -A egress_chain -m dscp --dscp $PROTO -j MARK --set-mark 1
  done

  # Mark bulk packets based on source LAN ip address and port number
  mark_addr_out "$IP_BULK" 4

  # Mark prio packets based on source LAN ip address and port number
  mark_addr_out "$IP_PRIO" 2

  # Mark expr packets based on source LAN ip address and port number
  mark_addr_out "$IP_EXPR" 1

  # Call mark_chain
  iptables -t mangle -A egress_chain -j mark_chain

  # Make sure ACK packets get priority (to avoid upload speed limiting our download speed)
  iptables -t mangle -A egress_chain -p tcp -m length --length :128 --tcp-flags SYN,RST,ACK ACK -j MARK --set-mark 1
  ######################################################################################################

  [ "$DEBUG" -eq 1 ] && iptables -t mangle -A egress_chain -m mark --mark 0 -j LOG --log-prefix egress_0::
  [ "$DEBUG" -eq 1 ] && iptables -t mangle -A egress_chain -m mark --mark 0 -j ACCEPT
  [ "$DEBUG" -eq 1 ] && iptables -t mangle -A egress_chain -m mark --mark 1 -j LOG --log-prefix egress_1::
  [ "$DEBUG" -eq 1 ] && iptables -t mangle -A egress_chain -m mark --mark 1 -j ACCEPT
  [ "$DEBUG" -eq 1 ] && iptables -t mangle -A egress_chain -m mark --mark 2 -j LOG --log-prefix egress_2::
  [ "$DEBUG" -eq 1 ] && iptables -t mangle -A egress_chain -m mark --mark 2 -j ACCEPT
  [ "$DEBUG" -eq 1 ] && iptables -t mangle -A egress_chain -m mark --mark 3 -j LOG --log-prefix egress_3::
  [ "$DEBUG" -eq 1 ] && iptables -t mangle -A egress_chain -m mark --mark 3 -j ACCEPT
  [ "$DEBUG" -eq 1 ] && iptables -t mangle -A egress_chain -m mark --mark 4 -j LOG --log-prefix egress_4::
  [ "$DEBUG" -eq 1 ] && iptables -t mangle -A egress_chain -m mark --mark 4 -j ACCEPT
  [ "$DEBUG" -eq 1 ] && iptables -t mangle -A egress_chain -j LOG --log-prefix egress_other::

  [ "$DEBUG" -eq 1 ] && iptables -t mangle -A ingress_chain -m mark --mark 0 -j LOG --log-prefix ingress_0::
  [ "$DEBUG" -eq 1 ] && iptables -t mangle -A ingress_chain -m mark --mark 0 -j ACCEPT
  [ "$DEBUG" -eq 1 ] && iptables -t mangle -A ingress_chain -m mark --mark 1 -j LOG --log-prefix ingress_1::
  [ "$DEBUG" -eq 1 ] && iptables -t mangle -A ingress_chain -m mark --mark 1 -j ACCEPT
  [ "$DEBUG" -eq 1 ] && iptables -t mangle -A ingress_chain -m mark --mark 2 -j LOG --log-prefix ingress_2::
  [ "$DEBUG" -eq 1 ] && iptables -t mangle -A ingress_chain -m mark --mark 2 -j ACCEPT
  [ "$DEBUG" -eq 1 ] && iptables -t mangle -A ingress_chain -m mark --mark 3 -j LOG --log-prefix ingress_3::
  [ "$DEBUG" -eq 1 ] && iptables -t mangle -A ingress_chain -m mark --mark 3 -j ACCEPT
  [ "$DEBUG" -eq 1 ] && iptables -t mangle -A ingress_chain -m mark --mark 4 -j LOG --log-prefix ingress_4::
  [ "$DEBUG" -eq 1 ] && iptables -t mangle -A ingress_chain -m mark --mark 4 -j ACCEPT
  [ "$DEBUG" -eq 1 ] && iptables -t mangle -A ingress_chain -j LOG --log-prefix ingress_other::

fi
exit 0

