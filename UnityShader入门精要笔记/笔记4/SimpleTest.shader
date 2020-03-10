Shader "UShaderMagicBook/SimpleTest"{
    /*一个最基础的着色器*/

    Properties{
        _BaseColor("MyColor",Color) = (1.0,1.0,1.0,1.0)     //后面不能加分号
    }
    SubShader{
        //子着色器A

        pass{
            //第一个pass块

            CGPROGRAM
            #pragma vertex Vertex
            #pragma fragment Pixel
            /*定义你的顶点着色器的函数名称和片元着色器的函数名称，该步是必要的
            起什么名字无所谓，命名规则同C类语言命名规则
            1.区分大小写
            2.不以数字开头
            3.不能和系统关键字冲突*/
            
            fixed4 _BaseColor;
            /*光在Properties语块中定义变量是没用的，你必须在CGPROGRAM块中再次声明，Unity
            才会把变量材质面板的值填充过来*/

            float4 Vertex(float4 v:POSITION):SV_POSITION{
                /*定义顶点着色器,处理和模型顶点有关的内容
                一个顶点着色器至少要完成一件事，那就是把模型的顶点转换到
                裁剪空间*/

                return UnityObjectToClipPos(v);
                //把模型转换到裁剪空间
            }
            fixed4 Pixel():SV_TARGET{
                //计算模型表面每个像素值的颜色

                return _BaseColor;
            }
            ENDCG
        }
    }
}