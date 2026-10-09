"""
make_charts.py
Membuat 5 chart untuk README dari hasil query SQL.
Angka di bawah disalin dari output query Q2, Q3, Q4, Q8, Q10, Q12
(lihat folder sql/).

Jalankan dari folder utama proyek:
    python scripts/make_charts.py
Butuh: matplotlib  (pip install matplotlib)
"""
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib import font_manager
from matplotlib.patches import Patch

OUT = Path("images")
OUT.mkdir(exist_ok=True)

# pilih font yang tersedia di komputer
_available = {f.name for f in font_manager.fontManager.ttflist}
for _family in ["Segoe UI", "Helvetica Neue", "Liberation Sans", "Noto Sans", "Arial", "DejaVu Sans"]:
    if _family in _available:
        plt.rcParams["font.family"] = _family
        break

PAPER = "#FBF9F5"
INK = "#2B2B2B"
MUTED = "#7A756C"
LINE = "#DDD7CC"
NEUTRAL = "#CFC8BA"
GOOD = "#4F7F6F"
BAD = "#C2593A"
SLATE = "#5B6B7A"
SAND = "#D2BE98"
SAGE = "#9DB3A8"

SOURCE = "Sumber: US DOT, penerbangan domestik AS 2015 (Kaggle). Diolah dengan PostgreSQL."


def idn(v, d=2):
    """Format angka ala Indonesia (koma desimal)."""
    return f"{v:.{d}f}".replace(".", ",")


def new_fig(size):
    fig = plt.figure(figsize=size, dpi=200)
    fig.patch.set_facecolor(PAPER)
    return fig


def style(ax):
    ax.set_facecolor(PAPER)
    for side in ("top", "right", "left"):
        ax.spines[side].set_visible(False)
    ax.spines["bottom"].set_color(LINE)
    ax.tick_params(length=0, colors=INK)


def header(fig, title, subtitle):
    fig.text(0.02, 0.965, title, fontsize=14.5, fontweight="bold",
             color=INK, ha="left", va="top")
    fig.text(0.02, 0.905, subtitle, fontsize=10, color=MUTED, ha="left", va="top")


def footer(fig):
    fig.text(0.02, 0.015, SOURCE, fontsize=8, color=MUTED, ha="left", va="bottom")


def hbar(ax, labels, values, colors, xmax, digits=2, suffix="%"):
    n = len(labels)
    ax.barh(range(n), values, color=colors, height=0.68, zorder=2)
    ax.set_yticks(range(n))
    ax.set_yticklabels(labels, fontsize=10.5, color=INK)
    ax.set_xlim(0, xmax)
    ax.set_xticks([])
    ax.spines["bottom"].set_visible(False)
    ax.set_ylim(n - 0.4, -1.3)
    for i, v in enumerate(values):
        ax.text(v + xmax * 0.012, i, idn(v, digits) + suffix,
                va="center", fontsize=10, color=INK, zorder=5,
                bbox=dict(facecolor=PAPER, edgecolor="none", pad=1.5))


def ref_line(ax, x, n, label):
    ax.vlines(x, -0.6, n - 0.4, color=INK, linewidth=1, linestyles=(0, (4, 3)), zorder=3, alpha=0.7)
    ax.text(x, -0.95, label, ha="center", va="center", fontsize=9, color=MUTED)


# ---------------------------------------------------------------
# Chart 1: % penerbangan telat >= 15 menit per maskapai (Q2)
# ---------------------------------------------------------------
delay_pct = [
    ("Hawaiian Airlines", 11.33), ("Alaska Airlines", 13.04), ("Delta Air Lines", 13.56),
    ("American Airlines", 18.27), ("SkyWest Airlines", 18.69), ("US Airways", 18.82),
    ("Southwest Airlines", 19.05), ("Virgin America", 19.23), ("Atlantic Southeast", 19.68),
    ("United Air Lines", 20.62), ("American Eagle", 21.72), ("JetBlue Airways", 22.58),
    ("Frontier Airlines", 26.16), ("Spirit Air Lines", 29.71),
]
labels = [a for a, _ in delay_pct]
values = [v for _, v in delay_pct]
colors = [GOOD] * 3 + [NEUTRAL] * 9 + [BAD] * 2

fig = new_fig((10, 6.4))
header(fig, "Hawaiian, Alaska, dan Delta paling jarang telat; Spirit paling sering",
       "Persentase penerbangan yang tiba telat 15 menit atau lebih, 2015 "
       "(penerbangan batal dan dialihkan tidak dihitung)")
ax = fig.add_axes([0.22, 0.07, 0.74, 0.76])
style(ax)
hbar(ax, labels, values, colors, xmax=36)
ref_line(ax, 18.61, len(labels), "rata-rata nasional 18,61%")
footer(fig)
fig.savefig(OUT / "01_delay_by_airline.png", facecolor=PAPER)
plt.close(fig)

# ---------------------------------------------------------------
# Chart 2: cancellation rate per maskapai (Q3)
# ---------------------------------------------------------------
cancel = [
    ("Hawaiian Airlines", 0.22), ("Alaska Airlines", 0.39), ("Delta Air Lines", 0.44),
    ("Frontier Airlines", 0.65), ("Virgin America", 0.86), ("Southwest Airlines", 1.27),
    ("United Air Lines", 1.27), ("American Airlines", 1.50), ("JetBlue Airways", 1.60),
    ("SkyWest Airlines", 1.69), ("Spirit Air Lines", 1.71), ("US Airways", 2.05),
    ("Atlantic Southeast", 2.66), ("American Eagle", 5.10),
]
labels = [a for a, _ in cancel]
values = [v for _, v in cancel]
colors = [GOOD] * 3 + [NEUTRAL] * 9 + [BAD] * 2

fig = new_fig((10, 6.4))
header(fig, "American Eagle membatalkan 3,3 kali lebih banyak dari rata-rata nasional",
       "Persentase penerbangan yang dibatalkan, per maskapai, 2015")
ax = fig.add_axes([0.22, 0.07, 0.74, 0.76])
style(ax)
hbar(ax, labels, values, colors, xmax=6.2)
ref_line(ax, 1.54, len(labels), "rata-rata nasional 1,54%")
footer(fig)
fig.savefig(OUT / "02_cancellation_by_airline.png", facecolor=PAPER)
plt.close(fig)

# ---------------------------------------------------------------
# Chart 3: % telat per bulan (Q8)
# ---------------------------------------------------------------
months = ["Jan", "Feb", "Mar", "Apr", "Mei", "Jun", "Jul", "Agu", "Sep", "Okt", "Nov", "Des"]
month_pct = [21.00, 23.35, 19.40, 17.16, 18.31, 23.48, 20.92, 18.67, 13.00, 12.44, 15.26, 20.60]
colors = [NEUTRAL] * 12
colors[1] = BAD
colors[5] = BAD
colors[8] = GOOD
colors[9] = GOOD

fig = new_fig((10, 5.6))
header(fig, "Dua puncak delay: Februari (musim dingin) dan Juni (musim panas)",
       "Persentase penerbangan telat tiba 15 menit atau lebih, per bulan, seluruh maskapai, 2015")
ax = fig.add_axes([0.03, 0.10, 0.94, 0.72])
style(ax)
ax.bar(range(12), month_pct, color=colors, width=0.66, zorder=2)
ax.set_xticks(range(12))
ax.set_xticklabels(months, fontsize=10.5)
ax.set_yticks([])
ax.set_xlim(-0.6, 12.9)
ax.set_ylim(0, 26.5)
for i, v in enumerate(month_pct):
    ax.text(i, v + 0.5, idn(v) + "%", ha="center", va="bottom", fontsize=9.5, color=INK)
ax.hlines(18.61, -0.6, 11.6, color=INK, linewidth=1, linestyles=(0, (4, 3)), alpha=0.7, zorder=3)
ax.text(11.75, 18.61, "rata-rata\nnasional\n18,61%", ha="left", va="center", fontsize=9, color=MUTED)
footer(fig)
fig.savefig(OUT / "03_delay_by_month.png", facecolor=PAPER)
plt.close(fig)

# ---------------------------------------------------------------
# Chart 4: penyebab delay (Q10) vs penyebab pembatalan (Q4)
# ---------------------------------------------------------------
fig = new_fig((11, 5.2))
header(fig, "Cuaca sering bikin penerbangan batal, tapi jarang jadi penyebab delay",
       "Kiri: penyebab delay (% dari total menit delay). Kanan: penyebab pembatalan (% dari penerbangan batal)")
fig.subplots_adjust(left=0.17, right=0.98, top=0.78, bottom=0.08, wspace=0.6)
ax1 = fig.add_subplot(1, 2, 1)
ax2 = fig.add_subplot(1, 2, 2)
for a in (ax1, ax2):
    style(a)

delay_causes = [("Efek domino\n(pesawat sebelumnya)", 39.84, NEUTRAL), ("Masalah maskapai", 32.20, NEUTRAL),
                ("Sistem lalu lintas\nudara (NAS)", 22.88, NEUTRAL), ("Cuaca ekstrem", 4.95, BAD),
                ("Keamanan", 0.13, NEUTRAL)]
hbar(ax1, [c[0] for c in delay_causes], [c[1] for c in delay_causes],
     [c[2] for c in delay_causes], xmax=50)
ax1.set_ylim(len(delay_causes) - 0.4, -0.6)
ax1.set_title("Penyebab delay", loc="left", fontsize=11, color=INK, fontweight="bold")

cancel_causes = [("Cuaca", 54.35, BAD), ("Masalah maskapai", 28.11, NEUTRAL),
                 ("Sistem lalu lintas\nudara (NAS)", 17.52, NEUTRAL), ("Keamanan", 0.02, NEUTRAL)]
hbar(ax2, [c[0] for c in cancel_causes], [c[1] for c in cancel_causes],
     [c[2] for c in cancel_causes], xmax=66)
ax2.set_ylim(len(cancel_causes) - 0.4, -0.6)
ax2.set_title("Penyebab pembatalan", loc="left", fontsize=11, color=INK, fontweight="bold")
footer(fig)
fig.savefig(OUT / "04_delay_vs_cancel_causes.png", facecolor=PAPER)
plt.close(fig)

# ---------------------------------------------------------------
# Chart 5: komposisi penyebab delay, 10 bandara asal terbesar (Q12)
# kolom: efek domino, maskapai, NAS, cuaca (% dari total menit delay)
# ---------------------------------------------------------------
airports = [
    ("Chicago O'Hare (ORD)", 37.0, 30.2, 22.7, 10.1),
    ("Atlanta (ATL)", 32.8, 37.6, 19.8, 9.8),
    ("Dallas/Fort Worth (DFW)", 35.9, 36.8, 18.3, 8.8),
    ("Denver (DEN)", 42.4, 31.3, 22.4, 3.8),
    ("Los Angeles (LAX)", 45.9, 32.4, 20.1, 1.5),
    ("Houston Bush (IAH)", 36.0, 34.4, 24.6, 4.8),
    ("San Francisco (SFO)", 49.6, 32.2, 16.6, 1.5),
    ("Las Vegas (LAS)", 45.3, 32.6, 20.0, 2.1),
    ("LaGuardia (LGA)", 47.5, 23.9, 24.7, 3.9),
    ("Orlando (MCO)", 40.6, 28.4, 23.8, 7.1),
]
seg_names = ["Efek domino", "Masalah maskapai", "Sistem udara (NAS)", "Cuaca ekstrem"]
seg_cols = [SLATE, SAND, SAGE, BAD]
txt_cols = ["white", INK, INK, "white"]

fig = new_fig((10, 6.2))
header(fig, "Hampir separuh delay di SFO, LGA, LAX, dan Las Vegas adalah efek domino",
       "Komposisi penyebab delay (% dari total menit delay) di 10 bandara asal dengan delay terbesar. "
       "Sisanya (<0,5%) keamanan")
fig.legend([Patch(color=c) for c in seg_cols], seg_names, loc="upper left",
           bbox_to_anchor=(0.012, 0.865), ncol=4, frameon=False, fontsize=9.5)
ax = fig.add_axes([0.21, 0.07, 0.75, 0.70])
style(ax)
for i, (name, *vals) in enumerate(airports):
    left = 0
    for j, v in enumerate(vals):
        ax.barh(i, v, left=left, color=seg_cols[j], height=0.72, edgecolor=PAPER, linewidth=1.2)
        if v >= 5:
            ax.text(left + v / 2, i, idn(v, 1), ha="center", va="center", fontsize=9, color=txt_cols[j])
        left += v
ax.set_yticks(range(len(airports)))
ax.set_yticklabels([a[0] for a in airports], fontsize=10.5, color=INK)
ax.set_ylim(len(airports) - 0.4, -0.6)
ax.set_xlim(0, 100)
ax.set_xticks([])
ax.spines["bottom"].set_visible(False)
footer(fig)
fig.savefig(OUT / "05_delay_causes_by_airport.png", facecolor=PAPER)
plt.close(fig)

print("Selesai. Chart tersimpan di folder:", OUT.resolve())
