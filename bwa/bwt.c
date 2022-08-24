/* The MIT License

Copyright (c) 2008 Genome Research Ltd (GRL).

    Permission is hereby granted, free of charge, to any person obtaining
    a copy of this software and associated documentation files (the
                                                               "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
                                                                  permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be
    included in all copies or substantial portions of the Software.

       THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
      NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
      BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
    ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
      CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
      SOFTWARE.
          */

/* Contact: Heng Li <lh3@sanger.ac.uk> */

#include "bwt.h"

#include <assert.h>
#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "kvec.h"
#include "utils.h"

#ifdef USE_MALLOC_WRAPPERS
#include "malloc_wrap.h"
#endif

#ifdef PERFORMANCE_COUNTERS
#include "performance_counters.h"
#endif

void bwt_gen_cnt_table(bwt_t* bwt) {
    int i, j;
    for (i = 0; i != 256; ++i) {
        uint32_t x = 0;
        for (j = 0; j != 4; ++j)
            x |= (((i & 3) == j) + ((i >> 2 & 3) == j) + ((i >> 4 & 3) == j) + (i >> 6 == j)) << (j << 3);
        bwt->cnt_table[i] = x;
    }
}

static inline bwtint_t bwt_invPsi(const bwt_t* bwt, bwtint_t k)  // compute inverse CSA
{
    bwtint_t x = k - (k > bwt->primary);
    x = bwt_B0(bwt, x);
    x = bwt->L2[x] + bwt_occ(bwt, k, x);
    return k == bwt->primary ? 0 : x;
}

// bwt->bwt and bwt->occ must be precalculated
void bwt_cal_sa(bwt_t* bwt, int intv) {
    bwtint_t isa, sa, i;  // S(isa) = sa
    int intv_round = intv;

    kv_roundup32(intv_round);
    xassert(intv_round == intv, "SA sample interval is not a power of 2.");
    xassert(bwt->bwt, "bwt_t::bwt is not initialized.");

    if (bwt->sa) free(bwt->sa);
    bwt->sa_intv = intv;
    bwt->n_sa = (bwt->seq_len + intv) / intv;
    bwt->sa = (bwtint_t*)calloc(bwt->n_sa, sizeof(bwtint_t));
    // calculate SA value
    isa = 0;
    sa = bwt->seq_len;
    for (i = 0; i < bwt->seq_len; ++i) {
        if (isa % intv == 0) bwt->sa[isa / intv] = sa;
        --sa;
        isa = bwt_invPsi(bwt, isa);
    }
    if (isa % intv == 0) bwt->sa[isa / intv] = sa;
    bwt->sa[0] = (bwtint_t)-1;  // before this line, bwt->sa[0] = bwt->seq_len
}

bwtint_t bwt_sa(const bwt_t* bwt, bwtint_t k) {
    bwtint_t sa = 0, mask = bwt->sa_intv - 1;
    while (k & mask) {
        ++sa;
        k = bwt_invPsi(bwt, k);
    }
    /* without setting bwt->sa[0] = -1, the following line should be
	   changed to (sa + bwt->sa[k/bwt->sa_intv]) % (bwt->seq_len + 1) */
    return sa + bwt->sa[k / bwt->sa_intv];
}

static inline int __occ_aux(uint64_t y, int c) {
    // reduce nucleotide counting to bits counting
    y = ((c & 2) ? y : ~y) >> 1 & ((c & 1) ? y : ~y) & 0x5555555555555555ull;
    // count the number of 1s in y
    y = (y & 0x3333333333333333ull) + (y >> 2 & 0x3333333333333333ull);
    return ((y + (y >> 4)) & 0xf0f0f0f0f0f0f0full) * 0x101010101010101ull >> 56;
}

bwtint_t bwt_occ(const bwt_t* bwt, bwtint_t k, ubyte_t c) {
    bwtint_t n;
    uint32_t *p, *end;

    if (k == bwt->seq_len) return bwt->L2[c + 1] - bwt->L2[c];
    if (k == (bwtint_t)(-1)) return 0;
    k -= (k >= bwt->primary);  // because $ is not in bwt

    // retrieve Occ at k/OCC_INTERVAL
    n = ((bwtint_t*)(p = bwt_occ_intv(bwt, k)))[c];
    p += sizeof(bwtint_t);  // jump to the start of the first BWT cell

    // calculate Occ up to the last k/32
    end = p + (((k >> 5) - ((k & ~OCC_INTV_MASK) >> 5)) << 1);
    for (; p < end; p += 2)
        n += __occ_aux((uint64_t)p[0] << 32 | p[1], c);

    // calculate Occ
    n += __occ_aux(((uint64_t)p[0] << 32 | p[1]) & ~((1ull << ((~k & 31) << 1)) - 1), c);
    if (c == 0) n -= ~k & 31;  // corrected for the masked bits

    return n;
}

// an analogy to bwt_occ() but more efficient, requiring k <= l
void bwt_2occ(const bwt_t* bwt, bwtint_t k, bwtint_t l, ubyte_t c, bwtint_t* ok, bwtint_t* ol) {
    bwtint_t _k, _l;
    _k = (k >= bwt->primary) ? k - 1 : k;
    _l = (l >= bwt->primary) ? l - 1 : l;
    if (_l / OCC_INTERVAL != _k / OCC_INTERVAL || k == (bwtint_t)(-1) || l == (bwtint_t)(-1)) {
        *ok = bwt_occ(bwt, k, c);
        *ol = bwt_occ(bwt, l, c);
    } else {
        bwtint_t m, n, i, j;
        uint32_t* p;
        if (k >= bwt->primary) --k;
        if (l >= bwt->primary) --l;
        n = ((bwtint_t*)(p = bwt_occ_intv(bwt, k)))[c];
        p += sizeof(bwtint_t);
        // calculate *ok
        j = k >> 5 << 5;
        for (i = k / OCC_INTERVAL * OCC_INTERVAL; i < j; i += 32, p += 2)
            n += __occ_aux((uint64_t)p[0] << 32 | p[1], c);
        m = n;
        n += __occ_aux(((uint64_t)p[0] << 32 | p[1]) & ~((1ull << ((~k & 31) << 1)) - 1), c);
        if (c == 0) n -= ~k & 31;  // corrected for the masked bits
        *ok = n;
        // calculate *ol
        j = l >> 5 << 5;
        for (; i < j; i += 32, p += 2)
            m += __occ_aux((uint64_t)p[0] << 32 | p[1], c);
        m += __occ_aux(((uint64_t)p[0] << 32 | p[1]) & ~((1ull << ((~l & 31) << 1)) - 1), c);
        if (c == 0) m -= ~l & 31;  // corrected for the masked bits
        *ol = m;
    }
}

#define __occ_aux4(bwt, b) \
    ((bwt)->cnt_table[(b)&0xff] + (bwt)->cnt_table[(b) >> 8 & 0xff] + (bwt)->cnt_table[(b) >> 16 & 0xff] \
     + (bwt)->cnt_table[(b) >> 24])

void bwt_occ4(const bwt_t* bwt, bwtint_t k, bwtint_t cnt[4]) {
    bwtint_t x;
    uint32_t *p, tmp, *end;
    if (k == (bwtint_t)(-1)) {
        memset(cnt, 0, 4 * sizeof(bwtint_t));
        return;
    }
    k -= (k >= bwt->primary);  // because $ is not in bwt
    p = bwt_occ_intv(bwt, k);
    memcpy(cnt, p, 4 * sizeof(bwtint_t));
    p += sizeof(bwtint_t);                               // sizeof(bwtint_t) = 4*(sizeof(bwtint_t)/sizeof(uint32_t))
    end = p + ((k >> 4) - ((k & ~OCC_INTV_MASK) >> 4));  // this is the end point of the following loop
    for (x = 0; p < end; ++p)
        x += __occ_aux4(bwt, *p);
    tmp = *p & ~((1U << ((~k & 15) << 1)) - 1);
    // TILL: subtract number of masked out bases from 'A's count (__occ_aux4 counts 00 as 'A')
    x += __occ_aux4(bwt, tmp) - (~k & 15);

    cnt[0] += x & 0xff;
    cnt[1] += x >> 8 & 0xff;
    cnt[2] += x >> 16 & 0xff;
    cnt[3] += x >> 24;
}

// an analogy to bwt_occ4() but more efficient, requiring k <= l
void bwt_2occ4(
    const bwt_t* bwt,
    bwtint_t k,
    bwtint_t l,
    bwtint_t cntk[4],
    bwtint_t cntl[4]
#if defined(PERFORMANCE_COUNTERS) && !defined(PERFORMANCE_COUNTERS_LOW_OVERHEAD)
    ,
    int is_back
#endif
) {
    /** TILL
     * Lookup in der Occ-Tabelle für alle 4 Basen für Startposition k und Endposition l des aktuellen Intervalls
     */
    bwtint_t _k, _l;
    _k = k - (k >= bwt->primary);
    _l = l - (l >= bwt->primary);
    if (_l >> OCC_INTV_SHIFT != _k >> OCC_INTV_SHIFT || k == (bwtint_t)(-1) || l == (bwtint_t)(-1)) {
        bwt_occ4(bwt, k, cntk);
        bwt_occ4(bwt, l, cntl);
#if defined(PERFORMANCE_COUNTERS) && !defined(PERFORMANCE_COUNTERS_LOW_OVERHEAD)
        if (_k != -1) performance_counters_log_bwt_access(_k, is_back);
        if (_l != -1) performance_counters_log_bwt_access(_l, is_back);
#endif
    } else {
        bwtint_t x, y;
        uint32_t *p, tmp, *endk, *endl;
        k -= (k >= bwt->primary);  // because $ is not in bwt
        l -= (l >= bwt->primary);
#if defined(PERFORMANCE_COUNTERS) && !defined(PERFORMANCE_COUNTERS_LOW_OVERHEAD)
        performance_counters_log_bwt_access(k, is_back);
#endif
        p = bwt_occ_intv(bwt, k);
        memcpy(cntk, p, 4 * sizeof(bwtint_t));
        p += sizeof(bwtint_t);  // sizeof(bwtint_t) = 4*(sizeof(bwtint_t)/sizeof(uint32_t))
        // prepare cntk[]
        endk = p + ((k >> 4) - ((k & ~OCC_INTV_MASK) >> 4));
        endl = p + ((l >> 4) - ((l & ~OCC_INTV_MASK) >> 4));
        for (x = 0; p < endk; ++p)
            x += __occ_aux4(bwt, *p);
        y = x;
        tmp = *p & ~((1U << ((~k & 15) << 1)) - 1);
        x += __occ_aux4(bwt, tmp) - (~k & 15);
        // calculate cntl[] and finalize cntk[]
        for (; p < endl; ++p)
            y += __occ_aux4(bwt, *p);
        tmp = *p & ~((1U << ((~l & 15) << 1)) - 1);
        y += __occ_aux4(bwt, tmp) - (~l & 15);
        memcpy(cntl, cntk, 4 * sizeof(bwtint_t));
        cntk[0] += x & 0xff;
        cntk[1] += x >> 8 & 0xff;
        cntk[2] += x >> 16 & 0xff;
        cntk[3] += x >> 24;
        cntl[0] += y & 0xff;
        cntl[1] += y >> 8 & 0xff;
        cntl[2] += y >> 16 & 0xff;
        cntl[3] += y >> 24;
    }
}

int bwt_match_exact(const bwt_t* bwt, int len, const ubyte_t* str, bwtint_t* sa_begin, bwtint_t* sa_end) {
    bwtint_t k, l, ok, ol;
    int i;
    k = 0;
    l = bwt->seq_len;
    for (i = len - 1; i >= 0; --i) {
        ubyte_t c = str[i];
        if (c > 3) return 0;  // no match
        bwt_2occ(bwt, k - 1, l, c, &ok, &ol);
        k = bwt->L2[c] + ok + 1;
        l = bwt->L2[c] + ol;
        if (k > l) break;  // no match
    }
    if (k > l) return 0;  // no match
    if (sa_begin) *sa_begin = k;
    if (sa_end) *sa_end = l;
    return l - k + 1;
}

int bwt_match_exact_alt(const bwt_t* bwt, int len, const ubyte_t* str, bwtint_t* k0, bwtint_t* l0) {
    int i;
    bwtint_t k, l, ok, ol;
    k = *k0;
    l = *l0;
    for (i = len - 1; i >= 0; --i) {
        ubyte_t c = str[i];
        if (c > 3) return 0;  // there is an N here. no match
        bwt_2occ(bwt, k - 1, l, c, &ok, &ol);
        k = bwt->L2[c] + ok + 1;
        l = bwt->L2[c] + ol;
        if (k > l) return 0;  // no match
    }
    *k0 = k;
    *l0 = l;
    return l - k + 1;
}

/*********************
 * Bidirectional BWT *
 *********************/

void bwt_extend(const bwt_t* bwt, const bwtintv_t* ik, bwtintv_t ok[4], int is_back) {
    /** TILL
     * Siehe:   Algorithm 2: Backward extension,
     *          Exploring single-sample SNP and INDEL calling with whole-genome de novo assembly, Heng Li, 2012
     *          https://academic.oup.com/bioinformatics/article/28/14/1838/218887
     * R: Referenz, ~R: Watson-Crick reverse complement der Referenz: BWT = R + ~R
     * Ermöglicht bidirektionale Suche!
     * x[0]: Startposition des Query-Strings auf der BWT
     * x[1]: Startposition des Watson-Crick reverse complement des Query-Strings auf der BWT
     * x[2]: Größe des Intervalls (ist für x[0] und x[2] gleich, da die BWT Konkatenation von R und ~R ist)
     * in ok[4] werden die erweiterten Intervalle für alle 4 Basen ausgehend von Intervall ik gespeichert
     * Wenn x[0] rückwärts erweitert wird, dann wird x[1] vorwärts erweitert (und andersherum).
     * Die neuen Intervalle der Vorwärtserweiterung können aus den Größen der neuen Intervalle der Rückwärtserweiterung berechnet werden.
     */
#if defined(PERFORMANCE_COUNTERS) && !defined(PERFORMANCE_COUNTERS_LOW_OVERHEAD)
    performance_counters_log_bwt_extend_call(is_back);
#endif

    bwtint_t tk[4], tl[4];
    int i;
    bwt_2occ4(
        bwt,
        ik->x[!is_back] - 1,
        ik->x[!is_back] - 1 + ik->x[2],
        tk,
        tl
#if defined(PERFORMANCE_COUNTERS) && !defined(PERFORMANCE_COUNTERS_LOW_OVERHEAD)
        ,
        is_back
#endif
    );
    for (i = 0; i != 4; ++i) {
        ok[i].x[!is_back] = bwt->L2[i] + 1 + tk[i];
        ok[i].x[2] = tl[i] - tk[i];
    }
    ok[3].x[is_back] =
        ik->x[is_back] + (ik->x[!is_back] <= bwt->primary && ik->x[!is_back] + ik->x[2] - 1 >= bwt->primary);
    ok[2].x[is_back] = ok[3].x[is_back] + ok[3].x[2];
    ok[1].x[is_back] = ok[2].x[is_back] + ok[2].x[2];
    ok[0].x[is_back] = ok[1].x[is_back] + ok[1].x[2];
}

static void bwt_reverse_intvs(bwtintv_v* p) {
    if (p->n > 1) {
        int j;
        for (j = 0; j < p->n >> 1; ++j) {
            bwtintv_t tmp = p->a[p->n - 1 - j];
            p->a[p->n - 1 - j] = p->a[j];
            p->a[j] = tmp;
        }
    }
}
// NOTE: $max_intv is not currently used in BWA-MEM
int bwt_smem1a(
    const bwt_t* bwt,
    int len,
    const uint8_t* q,
    int x,
    int min_intv,
    uint64_t max_intv,
    bwtintv_v* mem,
    bwtintv_v* tmpvec[2]) {
    /** TILL
     * *** Prozedur bei SMEM-Suche (min_intv = 1, max_intv = 0) ***
     * Zuerst wird das SA-Interval ausgehend von Position x vorwärts Base für Base erweitert. Immer, wenn das Interval durch
     * eine Erweiterung kleiner wird, wird das vorherige Interval gespeichert. Dies wird wiederholt, bis das Interval nicht
     * mehr erweiterbar ist, weil man am Ende der Query angelangt ist, oder es keine Matches mehr auf der Referenz gibt.
     * Danach werden die Intervalle nach Länge absteigend sortiert. Die längsten Matches mit dem kleinsten Interval
     * kommen also vorne. Nun werden alle Intervalle Base für Base rückwärts erweitert. Wenn ein Interval nicht mehr
     * erweitert werden kann, wird es als SMEM abgespeichert. Ansonsten wird es zur nächsten Erweiterungsrunde übernommen.
     * Da die Intervalle sortiert sind, ist jedes Interval ein Substring des vorherigen Intervals.
     * Hat ein erweitertes Interval nach einer Rückwärtserweiterung nicht mehr Vorkommen in der Referenz, als das vorherige,
     * ist es redundant und kann verworfen werden. (Es enthält keine Referenzpositionen, die das längere Interval nicht auch enthält.)
     *
     * ** Rückwärtserweiterung: **
     *             x
     *           A|ACGTTACG => Matches: 1 -> als SMEM speichern
     *         TCA|ACGTTA   => Matches: 5 -> erweitern
     *         TCA|ACGT     => Matches: 5 -> verwerfen
     *         TCA|AC       => Matches: 8 -> erweitern
     **/

    int i, j, c, ret;
    bwtintv_t ik, ok[4];
    bwtintv_v a[2], *prev, *curr, *swap;

    mem->n = 0;
    if (q[x] > 3) return x + 1;
    if (min_intv < 1) min_intv = 1;  // the interval size should be at least 1
    kv_init(a[0]);
    kv_init(a[1]);
    prev = tmpvec && tmpvec[0] ? tmpvec[0] : &a[0];  // use the temporary vector if provided
    curr = tmpvec && tmpvec[1] ? tmpvec[1] : &a[1];
    bwt_set_intv(bwt, q[x], ik);  // the initial interval of a single base
    ik.info = x + 1;

    for (i = x + 1, curr->n = 0; i < len; ++i) {  // forward search
        if (ik.x[2] < max_intv) {                 // an interval small enough
            kv_push(bwtintv_t, *curr, ik);
            break;
        } else if (q[i] < 4) {  // an A/C/G/T base
            c = 3 - q[i];       // complement of q[i]
            bwt_extend(bwt, &ik, ok, 0);
            if (ok[c].x[2] != ik.x[2]) {  // change of the interval size
                kv_push(bwtintv_t, *curr, ik);
                if (ok[c].x[2] < min_intv) break;  // the interval size is too small to be extended further
            }
            ik = ok[c];
            ik.info = i + 1;
        } else {  // an ambiguous base
            kv_push(bwtintv_t, *curr, ik);
            break;  // always terminate extension at an ambiguous base; in this case, i<len always stands
        }
    }
    if (i == len) kv_push(bwtintv_t, *curr, ik);  // push the last interval if we reach the end
    bwt_reverse_intvs(curr);                      // s.t. smaller intervals (i.e. longer matches) visited first
    ret = curr->a[0].info;                        // this will be the returned value
    swap = curr;
    curr = prev;
    prev = swap;

    for (i = x - 1; i >= -1; --i) {             // backward search for MEMs
        c = i < 0 ? -1 : q[i] < 4 ? q[i] : -1;  // c==-1 if i<0 or q[i] is an ambiguous base
        for (j = 0, curr->n = 0; j < prev->n; ++j) {
            bwtintv_t* p = &prev->a[j];
            if (c >= 0 && ik.x[2] >= max_intv) bwt_extend(bwt, p, ok, 1);
            if (c < 0 || ik.x[2] < max_intv
                || ok[c].x[2]
                    < min_intv) {  // keep the hit if reaching the beginning or an ambiguous base or the intv is small enough
                if (curr->n == 0) {  // test curr->n>0 to make sure there are no longer matches
                    if (mem->n == 0 || i + 1 < mem->a[mem->n - 1].info >> 32) {  // skip contained matches
                        ik = *p;
                        ik.info |= (uint64_t)(i + 1) << 32;
                        kv_push(bwtintv_t, *mem, ik);
                    }
                }  // otherwise the match is contained in another longer match
            } else if (curr->n == 0 || ok[c].x[2] != curr->a[curr->n - 1].x[2]) {
                ok[c].info = p->info;
                kv_push(bwtintv_t, *curr, ok[c]);
            }
        }
        if (curr->n == 0) break;
        swap = curr;
        curr = prev;
        prev = swap;
    }
    // TODO-TILL: Investigate whether this has any impact at all
    //bwt_reverse_intvs(mem);  // s.t. sorted by the start coordinate

    if (tmpvec == 0 || tmpvec[0] == 0) free(a[0].a);
    if (tmpvec == 0 || tmpvec[1] == 0) free(a[1].a);
    return ret;
}

#ifdef ALT_SMEM_ACCELERATOR

bwtintv_t bwt_extend_forward(const bwt_t* bwt, bwtintv_t ik, uint8_t base) {
    bwtintv_t ok[4];
    bwt_extend(bwt, &ik, ok, 0);
    return ok[3 - base];
}

bwtintv_t bwt_extend_backward(const bwt_t* bwt, bwtintv_t ik, uint8_t base) {
    bwtintv_t ok[4];
    ok[base].info = ik.info;
    bwt_extend(bwt, &ik, ok, 1);
    return ok[base];
}

int bwt_smem1(
#if defined(SHORTCUT_SINGLE_CANDIDATE_MATCH)
    const bntseq_t* bns,
    const uint8_t* pac,
#endif
    const bwt_t* bwt,
    int len,
    const uint8_t* q,
    int x,
    int min_intv,
    bwtintv_v* mem,
    bwtintv_v* tmpvec[2]) {
    bwtintv_v smem_candidates;
    kv_init(smem_candidates);

    bwtintv_v* smem_candidates_addr;
    if (tmpvec && tmpvec[0]) {
        smem_candidates_addr = tmpvec[0];
        smem_candidates_addr->n = 0;
    } else {
        smem_candidates_addr = &smem_candidates;
    }

    min_intv = min_intv < 1 ? 1 : min_intv;

    // ambiguous base
    if (q[x] > 3) return x + 1;

    bwt_smem_forward(
#if defined(SHORTCUT_SINGLE_CANDIDATE_MATCH)
        bns,
        pac,
#endif
        bwt,
        len,
        q,
        x,
        min_intv,
        smem_candidates_addr);
    int ret = back(smem_candidates_addr).info;
    bwt_smem_backward(bwt, len, q, x, min_intv, smem_candidates_addr, mem);
    kv_destroy(smem_candidates);

    //        bwtintv_v ref_mem; kv_init(ref_mem);
    //        if (ret != bwt_smem1a(bwt, len, q, x, min_intv, 0, &ref_mem, tmpvec) || ref_mem.n != mem->n)
    //            fprintf(stderr, "Alternative Implementation has incorrect result.\n");
    //        kv_destroy(ref_mem);
    return ret;
}

#ifdef SHORTCUT_SINGLE_CANDIDATE_MATCH
#define _get_pac(pac, l) ((pac)[(l) >> 2] >> ((~(l)&3) << 1) & 3)
void get_sequence(int64_t l_pac, const uint8_t* pac, int64_t beg, int64_t end, uint8_t* seq) {
    if (end < beg) end ^= beg, beg ^= end, end ^= beg;  // if end is smaller, swap
    if (end > l_pac << 1) end = l_pac << 1;
    if (beg < 0) beg = 0;
    if (beg >= l_pac || end <= l_pac) {
        int64_t k, l = 0;
        if (beg >= l_pac) {  // reverse strand
            int64_t beg_f = (l_pac << 1) - 1 - end;
            int64_t end_f = (l_pac << 1) - 1 - beg;
            for (k = end_f; k > beg_f; --k)
                seq[l++] = 3 - _get_pac(pac, k);
        } else {  // forward strand
            for (k = beg; k < end; ++k)
                seq[l++] = _get_pac(pac, k);
        }
    }
}

int get_smem_end_position(
    const bntseq_t* bns,
    const uint8_t* pac,
    const bwt_t* bwt,
    bwtintv_t ik,
    const uint8_t* query,
    int query_length,
    int start_query_index,
    int current_query_index) {
    int64_t rbeg = bwt_sa(bwt, ik.x[0]);
    uint8_t* ref = malloc(query_length * sizeof(uint8_t));

    //get_sequence(bns->l_pac, pac, rbeg + current_query_index - start_query_index, rbeg + query_length - start_query_index, ref);
    int64_t beg = rbeg + current_query_index - start_query_index;
    int64_t end = rbeg + query_length - start_query_index;
    int64_t l_pac = bns->l_pac;

    if (end < beg) end ^= beg, beg ^= end, end ^= beg;  // if end is smaller, swap
    if (end > l_pac << 1) end = l_pac << 1;
    if (beg < 0) beg = 0;


    int current_reference_index = 0;

    int64_t k;
    if (beg >= l_pac) {  // reverse strand
        int64_t beg_f = (l_pac << 1) - 1 - end;
        int64_t end_f = (l_pac << 1) - 1 - beg;
        for (k = end_f; k > beg_f; --k, current_query_index++)
            if (current_query_index >= query_length || 3 - _get_pac(pac, k) != query[current_query_index]) break;
    } else {  // forward strand
        for (k = beg; k < end; ++k, current_query_index++)
            if (current_query_index >= query_length || _get_pac(pac, k) != query[current_query_index]) break;
    }

    return current_query_index;
}
#endif

void bwt_smem_forward(
#if defined(SHORTCUT_SINGLE_CANDIDATE_MATCH)
    const bntseq_t* bns,
    const uint8_t* pac,
#endif
    const bwt_t* bwt,
    int len,
    const uint8_t* q,
    int x,
    int min_intv,
    bwtintv_v* smem_candidates) {
    bwtintv_t ik, ok;
    bwt_set_intv(bwt, q[x], ik);
    ik.info = x + 1;

#ifdef SHORTCUT_SINGLE_CANDIDATE_MATCH
    int shortcut_match_cooldown = 3;
#endif

    char current_sequence_element;
    int current_sequence_index;
    for (current_sequence_index = x + 1; current_sequence_index < len; current_sequence_index++) {
#ifdef SHORTCUT_SINGLE_CANDIDATE_MATCH
        if (ik.x[2] == 1 && !shortcut_match_cooldown--) {
            ik.x[1] = 0;  // Invalidate x[1], since calculation forward extension is skipped
            ik.info = get_smem_end_position(bns, pac, bwt, ik, q, len, x, current_sequence_index);
            kv_push(bwtintv_t, *smem_candidates, ik);
            return;
        }
#endif
        current_sequence_element = q[current_sequence_index];
        if (current_sequence_element < 4) {
            ok = bwt_extend_forward(bwt, ik, current_sequence_element);
            assert(!(ik.x[0] != ok.x[0]) || (ik.x[2] != ok.x[2]));
            if (ok.x[2] != ik.x[2]) {
                kv_push(bwtintv_t, *smem_candidates, ik);
                if (ok.x[2] < min_intv) break;
            }
            ik = ok;
            ik.info = current_sequence_index + 1;
        } else {  // an ambiguous base
            kv_push(bwtintv_t, *smem_candidates, ik);
            break;  // always terminate extension at an ambiguous base; in this case, i<len always stands
        }
    }

    if (current_sequence_index == len) kv_push(bwtintv_t, *smem_candidates, ik);
}

void bwt_smem_backward(
    const bwt_t* bwt,
    int len,
    const uint8_t* q,
    int x,
    int min_intv,
    bwtintv_v* smem_candidates,
    bwtintv_v* mem) {
    bwtintv_t ik, ok;
    int current_sequence_index = x - 1, filtered_candidates_end_index = 0;
#ifdef COMBINE_CANDIDATE_WITH_RESULT_BUFFER
    int current_result_insert_index = smem_candidates->n - 1;
#endif
    char current_sequence_element;
    mem->n = 0;
    for (int current_candidate_index, current_candidate_insert_index; current_sequence_index > -1;
         current_sequence_index--) {
#ifdef COMBINE_CANDIDATE_WITH_RESULT_BUFFER
        if (!(filtered_candidates_end_index <= current_result_insert_index)) break;
#else
        if (!(filtered_candidates_end_index < smem_candidates->n)) break;
#endif
        current_sequence_element = q[current_sequence_index];
#ifdef COMBINE_CANDIDATE_WITH_RESULT_BUFFER
        current_candidate_index = current_candidate_insert_index = current_result_insert_index;
        ik = smem_candidates->a[current_result_insert_index];
#else
        current_candidate_index = current_candidate_insert_index = smem_candidates->n - 1;
        ik = back(smem_candidates);
#endif

        int isAmbiguousBase = current_sequence_element >= 4;
        if (isAmbiguousBase) {
            // When reaching an ambiguous base, store the longest remaining candidate as match and return
            ik.info |= (uint64_t)(current_sequence_index + 1) << 32;
#ifdef COMBINE_CANDIDATE_WITH_RESULT_BUFFER
            smem_candidates->a[current_result_insert_index--] = ik;
            for (int i = smem_candidates->n - 1; i > current_result_insert_index; i--)
                kv_push(bwtintv_t, *mem, smem_candidates->a[i]);
#else
            kv_push(bwtintv_t, *mem, ik);
#endif
            return;
        }
        ok = bwt_extend_backward(bwt, ik, current_sequence_element);

        // Since the SMEM candidates are iterated by length in decreasing order,
        // once an interval is above min_intv, all following intervals are above as well.
        // Therefore, hasReachedMinIntervalSize is either true for the first candidate (and potentially following ones)
        // or it is false for all candidates.
        // Once this value was false, it never becomes true.
        int hasReachedMinIntervalSize = ok.x[2] < min_intv;
        if (hasReachedMinIntervalSize) {
            ik.info |= (uint64_t)(current_sequence_index + 1) << 32;
#ifdef COMBINE_CANDIDATE_WITH_RESULT_BUFFER
            smem_candidates->a[current_result_insert_index--] = ik;
            current_candidate_insert_index--;
#else
            kv_push(bwtintv_t, *mem, ik);
#endif
            current_candidate_index--;

            // Discard all candidates with hasReachedMinIntervalSize that are shorter than the match we pushed out
            // These are already contained in the match we pushed out.
            for (; current_candidate_index >= filtered_candidates_end_index; current_candidate_index--) {
                ik = smem_candidates->a[current_candidate_index];
                ok = bwt_extend_backward(bwt, ik, current_sequence_element);
                hasReachedMinIntervalSize = ok.x[2] < min_intv;
                if (!hasReachedMinIntervalSize) break;
            }
        }

        while (current_candidate_index >= filtered_candidates_end_index) {
            smem_candidates->a[current_candidate_insert_index--] = ok;
            current_candidate_index--;

            // Discard all candidates contained in longer candidate
            int isContainedInLongerCandidate;
            for (; current_candidate_index >= filtered_candidates_end_index; current_candidate_index--) {
                ik = smem_candidates->a[current_candidate_index];
                ok = bwt_extend_backward(bwt, ik, current_sequence_element);
                isContainedInLongerCandidate = ok.x[2] == smem_candidates->a[current_candidate_insert_index + 1].x[2];
                if (!isContainedInLongerCandidate) break;
            }
        }

        filtered_candidates_end_index = current_candidate_insert_index + 1;
    }

    // If reaching beginning of query sequence, push longest remaining interval out
#ifdef COMBINE_CANDIDATE_WITH_RESULT_BUFFER
    if (filtered_candidates_end_index <= current_result_insert_index) current_result_insert_index--;
#else
    if (filtered_candidates_end_index < smem_candidates->n) kv_push(bwtintv_t, *mem, back(smem_candidates));
#endif

#ifdef COMBINE_CANDIDATE_WITH_RESULT_BUFFER
    for (int i = smem_candidates->n - 1; i > current_result_insert_index; i--)
        kv_push(bwtintv_t, *mem, smem_candidates->a[i]);
#endif
    return;
}

#else

int bwt_smem1(const bwt_t* bwt, int len, const uint8_t* q, int x, int min_intv, bwtintv_v* mem, bwtintv_v* tmpvec[2]) {
    return bwt_smem1a(bwt, len, q, x, min_intv, 0, mem, tmpvec);
}

#endif


#ifdef ALT_SMEM_FORWARD

bwtintv_t bwt_smem_forward_search(const bwt_t* bwt, int len, const uint8_t* q, int x, uint32_t* interval_sizes) {
    int i, c;
    bwtintv_t ik, ok[4];

    bwt_set_intv(bwt, q[x], ik);  // the initial interval of a single base

    for (i = x + 1; i < len && q[i] < 4; ++i) {  // forward search
        if (ik.x[2] <= interval_sizes[i]) {
            ik.info = 0;
            return ik;
        }

        c = 3 - q[i];  // complement of q[i]
        bwt_extend(bwt, &ik, ok, 0);

        if (ok[c].x[2] == 0) break;  // the interval size is too small to be extended further
        ik = ok[c];
        interval_sizes[i] = ik.x[2];
    }

    ik.info = ((bwtint_t)x << 32) | (i);
    return ik;
}

#endif

int bwt_seed_strategy1(const bwt_t* bwt, int len, const uint8_t* q, int x, int min_len, int max_intv, bwtintv_t* mem) {
    int i, c;
    bwtintv_t ik, ok[4];

    memset(mem, 0, sizeof(bwtintv_t));
    if (q[x] > 3) return x + 1;
    bwt_set_intv(bwt, q[x], ik);     // the initial interval of a single base
    for (i = x + 1; i < len; ++i) {  // forward search
        if (q[i] < 4) {              // an A/C/G/T base
            c = 3 - q[i];            // complement of q[i]
            bwt_extend(bwt, &ik, ok, 0);
            if (ok[c].x[2] < max_intv && i - x >= min_len) {
                *mem = ok[c];
                mem->info = (uint64_t)x << 32 | (i + 1);
                return i + 1;
            }
            ik = ok[c];
        } else
            return i + 1;
    }
    return len;
}

/*************************
 * Read/write BWT and SA *
 *************************/

void bwt_dump_bwt(const char* fn, const bwt_t* bwt) {
    FILE* fp;
    fp = xopen(fn, "wb");
    err_fwrite(&bwt->primary, sizeof(bwtint_t), 1, fp);
    err_fwrite(bwt->L2 + 1, sizeof(bwtint_t), 4, fp);
    err_fwrite(bwt->bwt, 4, bwt->bwt_size, fp);
    err_fflush(fp);
    err_fclose(fp);
}

void bwt_dump_sa(const char* fn, const bwt_t* bwt) {
    FILE* fp;
    fp = xopen(fn, "wb");
    err_fwrite(&bwt->primary, sizeof(bwtint_t), 1, fp);
    err_fwrite(bwt->L2 + 1, sizeof(bwtint_t), 4, fp);
    err_fwrite(&bwt->sa_intv, sizeof(bwtint_t), 1, fp);
    err_fwrite(&bwt->seq_len, sizeof(bwtint_t), 1, fp);
    err_fwrite(bwt->sa + 1, sizeof(bwtint_t), bwt->n_sa - 1, fp);
    err_fflush(fp);
    err_fclose(fp);
}

static bwtint_t fread_fix(
    FILE* fp,
    bwtint_t size,
    void*
        a) {  // Mac/Darwin has a bug when reading data longer than 2GB. This function fixes this issue by reading data in small chunks
    const int bufsize = 0x1000000;  // 16M block
    bwtint_t offset = 0;
    while (size) {
        int x = bufsize < size ? bufsize : size;
        if ((x = err_fread_noeof(a + offset, 1, x, fp)) == 0) break;
        size -= x;
        offset += x;
    }
    return offset;
}

void bwt_restore_sa(const char* fn, bwt_t* bwt) {
    char skipped[256];
    FILE* fp;
    bwtint_t primary;

    fp = xopen(fn, "rb");
    err_fread_noeof(&primary, sizeof(bwtint_t), 1, fp);
    xassert(primary == bwt->primary, "SA-BWT inconsistency: primary is not the same.");
    err_fread_noeof(skipped, sizeof(bwtint_t), 4, fp);  // skip
    err_fread_noeof(&bwt->sa_intv, sizeof(bwtint_t), 1, fp);
    err_fread_noeof(&primary, sizeof(bwtint_t), 1, fp);
    xassert(primary == bwt->seq_len, "SA-BWT inconsistency: seq_len is not the same.");

    bwt->n_sa = (bwt->seq_len + bwt->sa_intv) / bwt->sa_intv;
    bwt->sa = (bwtint_t*)calloc(bwt->n_sa, sizeof(bwtint_t));
    bwt->sa[0] = -1;

    fread_fix(fp, sizeof(bwtint_t) * (bwt->n_sa - 1), bwt->sa + 1);
    err_fclose(fp);
}

bwt_t* bwt_restore_bwt(const char* fn) {
    bwt_t* bwt;
    FILE* fp;

    bwt = (bwt_t*)calloc(1, sizeof(bwt_t));
    fp = xopen(fn, "rb");
    err_fseek(fp, 0, SEEK_END);
    bwt->bwt_size = (err_ftell(fp) - sizeof(bwtint_t) * 5) >> 2;
    bwt->bwt = (uint32_t*)calloc(bwt->bwt_size, 4);
    err_fseek(fp, 0, SEEK_SET);
    err_fread_noeof(&bwt->primary, sizeof(bwtint_t), 1, fp);
    err_fread_noeof(bwt->L2 + 1, sizeof(bwtint_t), 4, fp);
    fread_fix(fp, bwt->bwt_size << 2, bwt->bwt);
    bwt->seq_len = bwt->L2[4];
    err_fclose(fp);
    bwt_gen_cnt_table(bwt);

    return bwt;
}

void bwt_destroy(bwt_t* bwt) {
    if (bwt == 0) return;
    free(bwt->sa);
    free(bwt->bwt);
    free(bwt);
}
