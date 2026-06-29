import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

# Maine BA percent bias under the two regional mortality levers (270-plot NB/NS/ME set).
# Multiplier: tree-level mort.mult (job 12102289). Cut-scale: stand-mortality cut (job 12102495).
mult_x = [1.0, 1.5, 2.0, 3.0]; mult_y = [11.1, 10.1, 9.1, 7.3]
cut_x  = [1.0, 0.8, 0.6, 0.4]; cut_y  = [11.1, 9.5, 8.0, 7.9]
# Plot lever "strength" increasing left->right: multiplier as-is; cut as (1/scale) so both grow rightward.
cut_strength = [1/s for s in cut_x]  # 1.0, 1.25, 1.67, 2.5

fig, ax = plt.subplots(figsize=(7.2, 4.6), dpi=150)
ax.axhline(0, color="#444", lw=1, ls="-")
ax.axhspan(7.0, 8.3, color="#d62728", alpha=0.10, lw=0)
ax.plot(mult_x, mult_y, "o-", color="#1f77b4", lw=2, ms=7, label="tree-level mortality multiplier")
ax.plot(cut_strength, cut_y, "s--", color="#ff7f0e", lw=2, ms=7, label="stand-mortality cut (1/scale)")
ax.text(2.55, 7.55, "tuning floor ~ +7 to +8%", color="#b22222", fontsize=9, va="center")
for x,y in zip(mult_x,mult_y): ax.annotate(f"{y:.1f}", (x,y), textcoords="offset points", xytext=(0,8), ha="center", fontsize=8, color="#1f77b4")
for x,y in zip(cut_strength,cut_y): ax.annotate(f"{y:.1f}", (x,y), textcoords="offset points", xytext=(0,-13), ha="center", fontsize=8, color="#cc6600")
ax.set_xlabel("regional mortality lever strength (rightward = more mortality)")
ax.set_ylabel("Maine basal-area bias (%)")
ax.set_title("Both regional mortality levers saturate above zero\nMaine BA bias vs lever strength (270-plot NB/NS/ME validation)", fontsize=11)
ax.set_ylim(-1, 12.5); ax.grid(alpha=0.25); ax.legend(loc="upper right", fontsize=9, framealpha=0.9)
fig.tight_layout()
out="/sessions/quirky-fervent-dijkstra/mnt/fvs-acd-site-update/figures/acadgy_mortality_lever_saturation.png"
fig.savefig(out); print("WROTE", out)
