散射理论中，不同的散射事件会通过不同的颜色系数来进行描述，其中吸收主要通过$\sigma_{a}$来描述，外散射和内散射主要通过$\sigma_{s}$来描述。

外散射和吸收都会导致光子的消散，所以它们可以总结为$\sigma_{t} = \sigma_a + \sigma_s$

散射和吸收系数决定了介质的albedo值$\rho$，定义如下：
$$
\rho = \frac{\sigma_s}{\sigma_s + \sigma_a} = \frac{\sigma_s}{\sigma_t}
$$
为了更精确，我们假设$L_i(c,-v) = L_o(p,v)$，其中$c$表示相机的位置，$p$表示从相机发射的射线与第一个接触的物体的交点坐标，$v$表示从$p$指向$c$的单位视角向量。但是一旦引入了一个媒介，那么这个假设就不再成立，我们需要考虑其中由于介质对光线所产生的各类散射事件影响，引发了光子的产生和消散而导致的辐射量的变化。于是$L_i(c,-v) = L_o(p,v)$将变更为：
$$
L_i(c,-v) = T_{r}(c,p)L_o(p,v) + \int_{t=0}^{||p-c||} T_{r}(c,c-vt)L_{scat}(c-vt,v)\sigma_{s}dt
$$

### 透射比（Transimttance）

其中$T_r(c,p)$表示的是从相机到物体表面的透射率，拆开该公式如下：
$$
T_{r}(c,x) = e^{-\tau} ,\quad where \quad \tau=\int_{x = x_{a}}^{x_{b}}\sigma_{t}(x)||dx||
$$
这个也就是**比尔·朗博定律（Beer-Lambert's Law）**，其中$\tau$是光学深度，表达的是光照衰减的强度，光穿越的距离越深，它衰减的强度就会越强，结果就是，越少的光线穿透介质，$\tau$为1的时候，大约可以减少60%的光照（***因为exp(-1)大约等于0.36，严格来说是减少了64%的光照***），如果$\sigma_t=(0.5,1,2)$的话，那么它的计算结果$e^{-d\sigma_t}$就是$(0.61, 0.37, 0.14)$，其中$d$​表示光学深度，此处设为1，即1米（一般来说，在图形学中是没有单位的概念的，因为现实世界和计算机世界的差异太大了，所以一般不怎么提到单位）

透射率会作用于三个部分

- $L_o(p,v)$，其实这里的$L_o(p,v)$就是摄像机拍摄到的画面，只不过Raymarching是发射多根射线，这里的$L_o(p,v)$只代表一根射线中采样得到的值，这也是该公式的第一个部分，即$T_{r}(c,p)L_o(p,v)$
- 内散射事件产生的辐射量$L_{scat}(x,v)$，（**这个部分暂时可以理解为，由于光路上的点受到光源的照射从而发光所产生的亮度**）
- 每条到光源的路径上的散射事件（**可以理解为每路径接受到的光照强度会由于此处的介质的浓度受到影响**）

### 散射事件（Scattering Events）

Raymarching路径上的点X到场景中点光源的内散射积分可以用如下公式来表述：
$$
L_{scat}(\mathbf{x},\mathbf{v})) = \pi\sum_{i=1}^{n}p(\mathbf{v},\Iota_{c_i})v(\mathbf{x},\mathbf{p}_{light_i})c_{light_i}(||\mathbf{x}-\mathbf{p}_{light_i}||)
$$
其中$n$表示灯光的数量，$p()$是相位函数，$v()$是能见度函数，$\Iota_{c_i}$是从$\mathbf{x}$射向第i个光源的方向，$\mathbf{P}_{light_i}$是第i个光源的位置，所以$c_{light_i}(||\mathbf{x}-\mathbf{p}_{light_i})$其实就是第i个光源的亮度和色彩，能见度函数$v(\mathbf{x},\mathbf{p}_{light_i})$代表了到达光路上的点$\mathbf{x}$的光的强度，定义如下：
$$
v(\mathbf{x},\mathbf{p}_{light_i}) = shadowMap(\mathbf{x},\mathbf{p}_{light_i}) \times volShad(\mathbf{x},\mathbf{p}_{light_i})
$$
其中$volShad(\mathbf{x},\mathbf{p}_{light_i}) = T_{r}(\mathbf{x},\mathbf{p}_{light_i})$,也就是光源到光路上的某个点$\mathbf{x}$的透射比，

为了让光照看起来符合现实，考虑$\sigma_t=(0.5,1,2)$，$\sigma_{a}=(0,0,0)$，在介质中较短的光路，内散射事件会大于消散事件，比如，外散射在该情况下，在深度比较浅的地方，$T_{r} \approx1$














$$
\int_{t=0}^{||p-c||} T_{r}(c,c-vt)L_{scat}(c-vt,v)\sigma_{s}dt
$$
其中，$\int_{t=0}^{||p-c||}$表示从摄像机的起点$c$开始朝着射线的终点$p$上每个点进行积分

而$T_{r}(c,c-vt)$等价于$T_{r}(c,x)$，表示从摄像机开始到途中的某个点X的总的透射比，其具体公式如下所示：
$$
T_{r}(c,x) = exp^{-\tau} ,\quad where \quad \tau=\int_{x = x_{a}}^{x_{b}}\sigma_{t}(x)||dx||
$$
