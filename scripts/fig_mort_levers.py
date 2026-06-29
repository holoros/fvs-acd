import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

# Maine BA percent bias under regional mortality levers (270-plot NB/NS/ME set).
# Single levers saturate; the combination breaks through.
mult_x = [1.0, 1.5, 2.0, 3.0]; mult_y = [11.1, 10.1, 9.1, 7.3]          # tree-level multiplier only
cut_x  = [1.0, 0.8, 0.6, 0.4]; cut_y  = [11.1, 9.5, 8.0, 7.9]            # stand cut only
cut_strength = [1/s for s in cut_x]
# Combined (cut 0.5 + multiplier), plotted at multiplier strength:
combo_x = [2.0, 3.0]; combo_y = [2.6, -2.3]

fig, ax = plt.subplots(figsize=(7.6, 4.8), dpi=150)
ax.axhline(0, color="#444", lw=1)
ax.axhspan(7.0, 8.3, color="#d62728", alpha=0.10, lw=0)
ax.plot(mult_x, mult_y, "o-", color="#1f77b4", lw=2, ms=7, label="multiplier only")
ax.plot(cut_strength, cut_y, "s--", color="#ff7f0e", lw=2, ms=7, label="stand cut only (1/scale)")
ax.plot(combo_x, combo_y, "*-", color="#2ca02c", lw=2, ms=15, label="cut 0.5 + multiplier (combined)")
ax.text(2.6, 7.6, "single-lever floor ~ +7 to +8%", color="#b22222", fontsize=9, va="center")
for x,y in zip(mult_x,mult_y): ax.annotate(f"{y:.1f}", (x,y), textcoords="offset points", xytext=(0,8), ha="center", fontsize=8, color="#1f77b4")
for x,y in zip(cut_strength,cut_y): ax.annotate(f"{y:.1f}", (x,y), textcoords="offset points", xytext=(0,-13), ha="center", fontsize=8, color="#cc6600")
for x,y in zip(combo_x,combo_y): ax.annotate(f"{y:+.1f}", (x,y), textcoords="offset points", xytext=(8,6), ha="left", fontsize=9, color="#1a7a1a", fontweight="bold")
ax.set_xlabel("mortality lever strength (rightward = more mortality)")
ax.set_ylabel("Maine basal-area bias (%)")
ax.set_title("Single levers saturate above zero; the combination closes the gap\nMaine BA bias, 270-plot NB/NS/ME validation (in-sample calibration)", fontsize=11)
ax.set_ylim(-4, 12.5); ax.grid(alpha=0.25); ax.legend(loc="center right", fontsize=9, framealpha=0.92)
fig.tight_layout()
out="/sessions/quirky-fervent-dijkstra/mnt/fvs-acd-site-update/figures/acadgy_mortality_lever_saturation.png"
fig.savefig(out); print("WROTE", out)
