# -*- coding: utf-8 -*-
"""
齿轮传动曲柄滑块往复机构 —— 逐帧运动学动画 + GIF
纯数学运动学渲染（不依赖 SolidWorks），参数与 00_设计说明书.md 完全一致。
帧参数：60 帧 @ 3 秒（20fps），主动齿轮转 2 圈、曲柄转 1 圈，无缝循环。
"""
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Circle, Polygon, Rectangle
import os, io
from PIL import Image

# ---- 字体（中文）----
plt.rcParams['font.sans-serif'] = ['Microsoft YaHei', 'SimHei', 'SimSun', 'DejaVu Sans']
plt.rcParams['axes.unicode_minus'] = False

# ---- 设计参数（与设计说明书一致）----
m, z1, z2, alpha_deg = 2.0, 20, 40, 20.0
alpha = np.radians(alpha_deg)
r_crank = 35.0       # 曲柄长
L_rod = 85.0         # 连杆长
a = 60.3             # 实际中心距（含 0.3 齿侧间隙）
slider_len = 160.0   # 滑块长
slider_h = 30.0      # 滑块高（示意）
gear1_c = np.array([0.0, 0.0])
gear2_c = np.array([a, 0.0])

def involute(t):
    return np.tan(t) - t

def gear_vertices(z, m, alpha):
    """渐开线直齿圆柱齿轮轮廓（原点为中心），返回闭合多边形 (N,2)。"""
    rp = m * z / 2.0
    ra = rp + m
    rd = rp - 1.25 * m
    rb = rp * np.cos(alpha)
    alpha_a = np.arccos(np.clip(rb / ra, -1.0, 1.0))
    half = np.pi / (2.0 * z)
    inv_a = involute(alpha)
    inv_aa = involute(alpha_a)
    pitch = 2.0 * np.pi / z
    n = 20
    P = []
    for k in range(z):
        c = k * pitch
        # 右齿廓：基圆 -> 齿顶圆
        al = np.linspace(0.0, alpha_a, n)
        r = rb / np.cos(al)
        ang = c + half - inv_a + involute(al)
        P += list(zip(r * np.cos(ang), r * np.sin(ang)))
        # 齿顶圆弧
        ang_rt = c + half - inv_a + inv_aa
        ang_lt = c - half + inv_a - inv_aa
        t = np.linspace(ang_rt, ang_lt, 6)
        P += list(zip(ra * np.cos(t), ra * np.sin(t)))
        # 左齿廓：齿顶圆 -> 基圆
        al2 = np.linspace(alpha_a, 0.0, n)
        r2 = rb / np.cos(al2)
        ang2 = c - half + inv_a - involute(al2)
        P += list(zip(r2 * np.cos(ang2), r2 * np.sin(ang2)))
        # 齿根过渡（径向）+ 齿根圆弧到下一齿
        ang_lb = c - half + inv_a
        ang_nrb = c + pitch + half - inv_a
        P.append((rd * np.cos(ang_lb), rd * np.sin(ang_lb)))
        tr = np.linspace(ang_lb, ang_nrb, 8)
        P += list(zip(rd * np.cos(tr), rd * np.sin(tr)))
    return np.array(P)

def rotate(pts, ang):
    c, s = np.cos(ang), np.sin(ang)
    R = np.array([[c, -s], [s, c]])
    return pts @ R.T

# 预生成两个齿轮轮廓（局部坐标）
g1 = gear_vertices(z1, m, alpha)
g2 = gear_vertices(z2, m, alpha)
# 齿轮2 初始相位：使齿轮1齿顶与齿轮2齿槽在啮合点对齐（错开半个齿距）
g2_phase = np.pi / z2

# ---- 帧参数 ----
N = 60
out_dir = r"C:\Users\zgzgd\Documents\DSH\精英联赛_设计包\动画"
os.makedirs(out_dir, exist_ok=True)

def slider_pin_x(phi):
    return a + r_crank * np.cos(phi) + np.sqrt(L_rod**2 - (r_crank * np.sin(phi))**2)

# 工件/工件台
work_c = np.array([356.0, 0.0])      # 工件 Ø30 圆心
work_R = 15.0

frames = []
fig = plt.figure(figsize=(12.8, 7.2), dpi=100)
for i in range(N):
    fig.clf()
    ax = fig.add_axes([0.0, 0.0, 1.0, 1.0])
    ax.set_aspect('equal')
    ax.set_xlim(-42, 402)
    ax.set_ylim(-56, 56)
    ax.axis('off')

    th1 = 4.0 * np.pi * i / N          # 主动齿轮转角（0 -> 2圈）
    th2 = -th1 / 2.0 + g2_phase        # 从动齿轮（反向 1:2）
    phi = -th1 / 2.0                   # 曲柄转角（与从动齿轮同步，反向）

    # ---- 齿轮 ----
    g1r = rotate(g1, th1) + gear1_c
    g2r = rotate(g2, th2) + gear2_c
    ax.add_patch(Polygon(g1r, closed=True, facecolor='#d8d8d8', edgecolor='#333333', lw=1.2))
    ax.add_patch(Polygon(g2r, closed=True, facecolor='#d8d8d8', edgecolor='#333333', lw=1.2))
    # 分度圆（虚线）
    ax.add_patch(Circle(gear1_c, 20.0, fill=False, ls=':', lw=0.6, ec='#888'))
    ax.add_patch(Circle(gear2_c, 40.0, fill=False, ls=':', lw=0.6, ec='#888'))
    # 轴心
    ax.add_patch(Circle(gear1_c, 2.2, fc='#333', ec='none'))
    ax.add_patch(Circle(gear2_c, 2.2, fc='#333', ec='none'))

    # ---- 曲柄（从动轴心 -> 曲柄销）----
    P_pin = gear2_c + r_crank * np.array([np.cos(phi), np.sin(phi)])
    ax.plot([gear2_c[0], P_pin[0]], [gear2_c[1], P_pin[1]], color='#c0392b', lw=5, solid_capstyle='round', zorder=5)
    ax.add_patch(Circle(P_pin, 4.0, fc='#c0392b', ec='#7b241c', lw=1, zorder=6))

    # ---- 连杆 ----
    x_s = slider_pin_x(phi)
    S = np.array([x_s, 0.0])
    ax.plot([P_pin[0], S[0]], [P_pin[1], S[1]], color='#2c3e50', lw=4.5, solid_capstyle='round', zorder=4)
    ax.add_patch(Circle(S, 3.0, fc='#2c3e50', ec='none', zorder=6))

    # ---- 导轨（两条平行轨道，覆盖滑块行程 + 工件区）----
    rail_y = slider_h / 2.0 + 2.0
    for yb in (rail_y, -rail_y):
        ax.plot([108, 392], [yb, yb], color='#999999', lw=3, zorder=1)
    for xg in range(108, 396, 20):
        ax.plot([xg, xg], [-rail_y, rail_y], color='#bbbbbb', lw=0.8, zorder=1)

    # ---- 滑块（销在滑块后端，推头在前端）----
    slider_x = x_s
    ax.add_patch(Rectangle((slider_x, -slider_h/2.0), slider_len, slider_h,
                           facecolor='#f4d03f', edgecolor='#7d6608', lw=1.4, zorder=3))
    # 推头
    ax.add_patch(Rectangle((slider_x + slider_len, -slider_h/2.0 - 3), 10, slider_h + 6,
                           facecolor='#e67e22', edgecolor='#7e5109', lw=1.2, zorder=3))

    # ---- 工件台 + 工件 ----
    ax.add_patch(Rectangle((330, -46), 62, 31, facecolor='#bdc3c7', edgecolor='#5d6d7e', lw=1.2, zorder=2))
    ax.add_patch(Circle(work_c, work_R, fc='#aab7b8', ec='#2e4053', lw=1.4, zorder=2))
    ax.add_patch(Circle(work_c, 2.0, fc='#2e4053', ec='none', zorder=2))

    # ---- 标注 ----
    ax.annotate('主动齿轮 z$_1$=20', (0, -26), ha='center', fontsize=9, color='#444')
    ax.annotate('从动齿轮 z$_2$=40', (60.3, -50), ha='center', fontsize=9, color='#444')
    ax.annotate('曲柄 r=35', (60.3, 40), ha='center', fontsize=9, color='#c0392b')
    ax.annotate('连杆 L=85', (105, 26), ha='center', fontsize=9, color='#2c3e50', rotation=-15)
    ax.annotate('滑块', (x_s + slider_len/2.0, 20), ha='center', fontsize=9, color='#7d6608')
    ax.annotate('工件', (356, 22), ha='center', fontsize=9, color='#2e4053')

    # ---- 标题 ----
    ax.text(180, 53, '齿轮传动曲柄滑块往复机构 — 运动仿真', ha='center', va='center',
            fontsize=17, fontweight='bold', color='#111')
    ax.text(180, 46, '电机 40 r/min → 齿轮减速 i=2 → 曲柄 20 r/min → 滑块行程 S=2r=70 mm',
            ha='center', va='center', fontsize=10.5, color='#555')

    # ---- 参数面板（左下）----
    params = (f"模数 m=2  压力角 α=20°\n"
              f"齿数 z1=20 / z2=40  传动比 i=2\n"
              f"中心距 a=60.3 mm（0.3 齿侧间隙）\n"
              f"曲柄 r=35 mm  连杆 L=85 mm\n"
              f"滑块行程 S=70 mm  自由度 F=1")
    ax.text(-40, -40, params, ha='left', va='bottom', fontsize=8.5, color='#333',
            bbox=dict(boxstyle='round,pad=0.5', fc='#fafafa', ec='#cccccc', lw=0.8))

    # ---- 转角指示（φ）----
    phi_deg = np.degrees(phi) % 360.0
    ax.text(60.3, -40, f'曲柄转角 φ = {phi_deg:.0f}°', ha='center', fontsize=10,
            color='#c0392b', fontweight='bold')

    # ---- 滑块位移-转角小图（右上角 inset）----
    axin = fig.add_axes([0.73, 0.60, 0.23, 0.30])
    phis = np.linspace(0, 2*np.pi, 200)
    xs = slider_pin_x(phis)
    axin.plot(np.degrees(phis), xs, color='#2c3e50', lw=1.6)
    axin.scatter([phi_deg], [x_s], color='#c0392b', s=40, zorder=5)
    axin.set_xlim(0, 360)
    axin.set_ylim(xs.min()-4, xs.max()+4)
    axin.set_xlabel('曲柄转角 φ (°)', fontsize=8)
    axin.set_ylabel('滑块位置 (mm)', fontsize=8)
    axin.set_title('滑块位移曲线', fontsize=9)
    axin.tick_params(labelsize=7)
    axin.grid(True, lw=0.3, alpha=0.4)
    # 标注行程
    axin.annotate('行程 70 mm', xy=(90, xs.max()-2), fontsize=7, color='#666')

    # ---- 渲染到内存 -> Pillow ----
    buf = io.BytesIO()
    fig.savefig(buf, format='png', dpi=100)
    buf.seek(0)
    im = Image.open(buf).convert('RGB')
    if i == 0:
        im.save(os.path.join(out_dir, '动画_第0帧预览.png'))
    frames.append(im)
    buf.close()

# ---- 合成 GIF（50ms/帧 = 20fps = 3秒，循环）----
gif_path = os.path.join(out_dir, '机构演示动画.gif')
frames[0].save(gif_path, save_all=True, append_images=frames[1:],
               duration=50, loop=0, optimize=True)
plt.close(fig)
print('GIF saved:', gif_path, os.path.getsize(gif_path), 'bytes,', len(frames), 'frames')
