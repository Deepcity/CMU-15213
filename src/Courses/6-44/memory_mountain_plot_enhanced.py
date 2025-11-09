
import argparse
import os
from io import StringIO
from pathlib import Path

import matplotlib
import numpy as np
import pandas as pd


def _has_display() -> bool:
    """Return True when a GUI display is likely available."""
    if os.name == "nt":
        return True
    return bool(os.environ.get("DISPLAY"))


DISPLAY_AVAILABLE = _has_display()
if not DISPLAY_AVAILABLE:
    matplotlib.use("Agg")

import matplotlib.pyplot as plt  # noqa: E402
from mpl_toolkits.mplot3d import Axes3D  # noqa: F401,E402

raw = '''size    s1      s2      s3      s4      s5      s6      s7      s8      s9      s10     s11     s12     s13     s14     s15
128m    10256   6048    4135    3206    2685    2277    1950    1751    1615    1548    1464    1401    1346    1308    1323
64m     11552   6655    4808    3739    3050    2578    2233    2008    1879    1740    1688    1642    1580    1613    1739
32m     15062   9540    6981    5436    4438    3721    3229    2874    2813    2789    2795    2801    2824    2839    2812
16m     22447   12558   8434    6344    5081    4244    3638    3180    3073    2997    2901    2815    2800    2767    2754
8m      23212   12745   8499    6376    5106    4286    3644    3188    3074    2974    2901    2819    2779    2757    2747
4m      23432   12762   8517    6586    5112    4260    3651    3194    3079    2983    2898    2815    2789    2771    2769
2m      23459   12986   9121    6557    5235    4356    3735    3265    3228    3255    3350    3498    3848    4054    4565
1024k   26162   19494   16447   13975   11900   10226   8911    7817    8887    10091   11259   12301   13513   14171   15043
512k    27995   23689   23033   23159   22182   20984   19274   17531   17375   17084   17154   17188   16934   16939   16687
256k    27999   24176   23777   23967   23862   22759   21113   20785   18551   19017   18379   17946   17936   17948   17675
128k    28047   24338   23772   24382   23914   22683   22070   16477   22175   18574   17816   18456   18738   14449   14568
64k     28143   24367   23834   23676   23552   22256   22238   22113   17665   19094   17944   17875   18117   17322   23087
32k     31265   29828   29291   28536   28474   27911   26901   26743   26391   26529   29710   29604   26860   27020   27236
16k     31482   30225   29355   28221   26357   25219   26055   27462   27345   27236   26911   25407   24941   23160   19454'''

DEFAULT_VIEW = (28.0, -125.0)
DEFAULT_SIZE_SLICES = ["128m", "8m", "32k"]
DEFAULT_STRIDE_SERIES = ["s1", "s2", "s4", "s8", "s16"]


def _case_insensitive_lookup(labels):
    """Return dict that maps lowercase labels to the original casing."""
    return {label.lower(): label for label in labels}

def parse_dataset():
    df_local = pd.read_csv(StringIO(raw), sep=r"\s+")

    def size_to_bytes(s):
        if s.endswith('k'):
            return int(s[:-1]) * 1024
        if s.endswith('m'):
            return int(s[:-1]) * 1024 * 1024
        return int(s)

    df_local['size_bytes'] = df_local['size'].map(size_to_bytes)
    stride_cols = [c for c in df_local.columns if c.startswith('s') and c[1:].isdigit()]
    return df_local, stride_cols


def parse_view(args):
    if args.view:
        try:
            elev_str, azim_str = args.view.split(',')
            return float(elev_str), float(azim_str)
        except ValueError as exc:
            raise ValueError(f"Invalid --view '{args.view}'. Expected 'elev,azim'.") from exc
    return DEFAULT_VIEW


def parse_slice_sizes(args, df_local):
    if args.slice_size:
        return args.slice_size
    # Fall back to defaults but drop any that are missing from this dataset
    available = _case_insensitive_lookup(df_local['size'])
    slices = []
    for label in DEFAULT_SIZE_SLICES:
        canonical = available.get(label.lower())
        if canonical:
            slices.append(canonical)
    return slices or df_local['size'].tolist()[:3]


def parse_stride_series(args, stride_cols):
    lookup = _case_insensitive_lookup(stride_cols)
    selected = []

    if args.stride:
        labels = args.stride
    else:
        labels = [label for label in DEFAULT_STRIDE_SERIES if label.lower() in lookup]
        if not labels:
            labels = stride_cols[:5]

    for raw_label in labels:
        key = raw_label.lower()
        if key not in lookup:
            raise ValueError(f"Stride '{raw_label}' not available. Choose from: {', '.join(stride_cols)}")
        canonical = lookup[key]
        if canonical not in selected:
            selected.append(canonical)

    return selected or stride_cols[:5]


def build_figure(df_local, stride_cols, view_angles, cmap, slice_sizes, stride_series):
    X = np.arange(1, len(stride_cols) + 1)
    Y_bytes = df_local['size_bytes'].values
    Z = df_local[stride_cols].astype(float).values

    row_idx = np.arange(len(Y_bytes))
    XX, _ = np.meshgrid(X, row_idx)
    Y_log2 = np.log2(Y_bytes)
    Y_log2_grid = np.tile(Y_log2.reshape(-1, 1), (1, len(X)))

    z_max = Z.max()
    max_row, max_col = np.unravel_index(np.argmax(Z), Z.shape)
    max_x = X[max_col]
    max_y_log2 = Y_log2[max_row]

    num_slices = max(len(slice_sizes), 1)
    side_rows = num_slices + 1  # extra row reserved for stride sections
    height_ratios = [1.6] + [1.0] * num_slices
    fig_local = plt.figure(figsize=(13, 4 + side_rows * 1.4))
    gs = fig_local.add_gridspec(side_rows, 2, width_ratios=[2.6, 1.0], height_ratios=height_ratios)

    cmap_obj = plt.get_cmap(cmap)
    z_floor = float(Z.min())

    ax3d = fig_local.add_subplot(gs[:, 0], projection='3d')
    surf = ax3d.plot_surface(XX, Y_log2_grid, Z, linewidth=0, antialiased=True, alpha=0.95, cmap=cmap_obj)
    ax3d.plot_wireframe(XX, Y_log2_grid, Z, rstride=2, cstride=2, linewidth=0.25, color='black', alpha=0.12)
    ax3d.contour(XX, Y_log2_grid, Z, zdir='z', offset=z_floor, cmap=cmap_obj)
    ax3d.plot(np.full_like(Y_log2, 1), Y_log2, Z[:, 0], linewidth=2, label='s1 ridge', color='#d62728')
    ax3d.plot(np.full_like(Y_log2, len(X)), Y_log2, Z[:, -1], linewidth=2, label='s15 ridge', color='#1f77b4')
    ax3d.scatter([max_x], [max_y_log2], [z_max], s=70, color='gold')
    ax3d.text(max_x, max_y_log2, z_max, f" max {int(z_max)} MB/s\n(s{max_col+1}, {df_local.loc[max_row, 'size']})", zdir=None)
    ax3d.set_xlabel("Stride (s1 … s15)")
    ax3d.set_ylabel("Working Set Size")
    ax3d.set_zlabel("Bandwidth (MB/s)")
    ax3d.set_yticks(Y_log2)
    ax3d.set_yticklabels(df_local['size'].tolist())
    ax3d.set_zlim(z_floor, Z.max() * 1.05)
    elev, azim = view_angles
    ax3d.view_init(elev=elev, azim=azim)
    ax3d.set_title("Memory Mountain (MB/s) — Surface + Sections")
    ax3d.legend(loc='upper right')

    size_labels = df_local['size'].tolist()
    x_idx = np.arange(len(size_labels))
    stride_colors = cmap_obj(np.linspace(0.15, 0.85, max(len(stride_series), 1)))

    ax_stride = fig_local.add_subplot(gs[0, 1])
    for idx_s, stride_label in enumerate(stride_series):
        series = df_local[stride_label].astype(float).values
        color = stride_colors[idx_s if len(stride_colors) > 1 else 0]
        ax_stride.plot(x_idx, series, marker='o', linewidth=2, color=color, label=stride_label)

    ax_stride.set_xticks(x_idx)
    ax_stride.set_xticklabels(size_labels, rotation=45, ha='right')
    ax_stride.set_xlabel("Working set size")
    ax_stride.set_ylabel("Bandwidth (MB/s)")
    ax_stride.set_title("Stride sections (X = working set size)")
    ax_stride.grid(alpha=0.25, linestyle='--')
    ax_stride.legend(title="Stride")

    slice_colors = cmap_obj(np.linspace(0.25, 0.9, max(num_slices, 1)))
    size_lookup = {label.lower(): idx for idx, label in enumerate(df_local['size'])}

    for idx, size_label in enumerate(slice_sizes):
        ax_slice = fig_local.add_subplot(gs[idx + 1, 1])
        row_position = size_lookup.get(size_label.lower())
        if row_position is None:
            raise ValueError(f"Slice size '{size_label}' not present in dataset.")
        row_values = df_local.iloc[row_position][stride_cols].astype(float).values
        color = slice_colors[idx if len(slice_colors) > 1 else 0]
        ax_slice.plot(X, row_values, marker='o', color=color, label=size_label)
        ax_slice.fill_between(X, row_values, color=color, alpha=0.18)
        ax_slice.set_title(f"Section @ {size_label}")
        ax_slice.set_xlabel("Stride index")
        ax_slice.set_ylabel("Bandwidth (MB/s)")
        ax_slice.set_xticks(X)
        ax_slice.set_xticklabels([f"s{i}" for i in X], rotation=45, ha='right')
        ax_slice.grid(alpha=0.3, linestyle='--')
        ax_slice.legend()

    if surf is not None:
        fig_local.colorbar(surf, ax=[ax3d], shrink=0.55, pad=0.08, label="Bandwidth (MB/s)")

    fig_local.tight_layout()
    return fig_local


def parse_args():
    parser = argparse.ArgumentParser(description="Render the Memory Mountain plot headlessly or with a GUI.")
    parser.add_argument(
        "--output",
        type=Path,
        default=None,
        help="Path to save the rendered figure. Defaults to memory_mountain.png when no display is available.",
    )
    parser.add_argument("--dpi", type=int, default=200, help="Resolution to use when saving figures.")
    parser.add_argument(
        "--colormap",
        default="viridis",
        help="Matplotlib colormap name to use for the surface.",
    )
    parser.add_argument(
        "--view",
        metavar="ELEV,AZIM",
        help="Set a custom 3D camera orientation (degrees). Example: --view 35,-95",
    )
    parser.add_argument(
        "--slice-size",
        action="append",
        dest="slice_size",
        metavar="SIZE",
        help="Add a working-set label (e.g., 128m, 1024k) to plot as a 2D section. Provide up to three.",
    )
    parser.add_argument(
        "--stride",
        action="append",
        dest="stride",
        metavar="STRIDE",
        help="Add a stride column (e.g., s1) to the working-set cross section plot.",
    )
    parser.add_argument(
        "--no-show",
        action="store_true",
        help="Skip opening a GUI window even when a display is available.",
    )
    return parser.parse_args()


def main():
    args = parse_args()
    df_local, stride_cols = parse_dataset()
    view_angles = parse_view(args)
    slice_sizes = parse_slice_sizes(args, df_local)
    stride_series = parse_stride_series(args, stride_cols)
    fig = build_figure(
        df_local,
        stride_cols,
        view_angles,
        cmap=args.colormap,
        slice_sizes=slice_sizes,
        stride_series=stride_series,
    )

    should_show = DISPLAY_AVAILABLE and not args.no_show
    output_path = args.output

    if not should_show and output_path is None:
        output_path = Path("memory_mountain.png")

    if output_path is not None:
        fig.savefig(output_path, dpi=args.dpi, bbox_inches='tight')
        print(f"Memory mountain plot saved to {output_path}")

    if should_show:
        plt.show()
    else:
        if DISPLAY_AVAILABLE and args.no_show:
            print("Skipped GUI window (--no-show provided).")
        else:
            print("Display not available; skipped interactive window.")

    plt.close(fig)


if __name__ == "__main__":
    main()
