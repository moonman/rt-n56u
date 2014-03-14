/*
 * This file is subject to the terms and conditions of the GNU General Public
 * License.  See the file "COPYING" in the main directory of this archive
 * for more details.
 *
 * Micro-assembler generated clear_page/copy_page functions.
 *
 * Copyright (C) 2012  MIPS Technologies, Inc.
 */
#include <asm/asm.h>
#include <asm/regdef.h>

/*
 * Maximum sizes:
 *
 * R4000 128 bytes S-cache:            0x058 bytes
 * R4600 v1.7:                         0x05c bytes
 * R4600 v2.0:                         0x060 bytes
 * With prefetching, 16 word strides   0x120 bytes
 */
EXPORT(__clear_page_start)
#ifdef CONFIG_SIBYTE_DMA_PAGEOPS
LEAF(clear_page_cpu)
#else
LEAF(clear_page)
#endif
1:     j       1b              /* Dummy, will be replaced. */
       .space 288
END(clear_page)
EXPORT(__clear_page_end)

/*
 * Maximum sizes:
 *
 * R4000 128 bytes S-cache:            0x11c bytes
 * R4600 v1.7:                         0x080 bytes
 * R4600 v2.0:                         0x07c bytes
 * With prefetching, 16 word strides   0x540 bytes
 */
EXPORT(__copy_page_start)
#ifdef CONFIG_SIBYTE_DMA_PAGEOPS
LEAF(copy_page_cpu)
#else
LEAF(copy_page)
#endif
1:     j       1b              /* Dummy, will be replaced. */
       .space 1344
END(copy_page)
EXPORT(__copy_page_end)
