Shader "Custom/RayMarchingStep2"
{
	Properties
	{
		_Radius("Radius", Range(0.0,1.0)) = 0.3
		// _BlurShadow("BlurShadow", Range(0.0,50.0)) = 16.0
		// _Speed("Speed", Range(0.0,10.0)) = 2.0
	}
	SubShader
	{
		Tags{ "Queue" = "Transparent" "LightMode"="ForwardBase"}
		LOD 100

		Pass
		{
			ZWrite On
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
            //ライティングの固有関数を使うため
			#include "Lighting.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 pos : POSITION1;
				float4 vertex : SV_POSITION;
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
                //ローカル→ワールド座標に変換
				o.pos = mul(unity_ObjectToWorld, v.vertex);
				o.uv = v.uv;
				return o;
			}

			// float _Radius,_BlurShadow,_Speed;
			float _Radius;

            //球の距離関数
			float sphere(float3 pos)
            {
                return length(pos) - _Radius;
            }

            // 法線の算出
			// https://qiita.com/edo_m18/items/3d95c2309d6ad5a6ba55
			float3 getNormal(float3 pos) {
                float d = 0.001;
                return normalize(float3(
                    sphere(pos + float3(d, 0, 0)) - sphere(pos + float3(-d, 0, 0)),
                    sphere(pos + float3(0, d, 0)) - sphere(pos + float3(0, -d, 0)),
                    sphere(pos + float3(0, 0, d)) - sphere(pos + float3(0, 0, -d))
                ));
            }


			fixed4 frag(v2f i) : SV_Target
			{

				// レイの初期位置
				float3 pos = i.pos.xyz;
				// レイの進行方向
				float3 rayDir = normalize(pos.xyz - _WorldSpaceCameraPos);

				int StepNum = 30;

                for (int i = 0; i < StepNum; i++) {
                    //行進する距離(球との最短距離分)
                    float marchingDist = sphere(pos);

                    //0.001以下になったら、ピクセルを白で塗って処理終了
                    if (marchingDist < 0.001) {

						//ライティング
						float3 lightDir = _WorldSpaceLightPos0.xyz;
						float3 normal = getNormal(pos);
						float3 lightColor = _LightColor0;

                        fixed4 col = fixed4(lightColor * max(dot(normal, lightDir), 0) , 1.0);
                        col.rgb += fixed3(0.2f, 0.2f, 0.2f);
						// return fixed4(lightColor * max(dot(normal, lightDir), 0) , 1.0));
						return col;
                    }
                    //レイの方向に行進する
                    pos.xyz += marchingDist * rayDir.xyz;
                }

                //StepNum回行進しても衝突判定がなかったら、ピクセルを透明にして処理終了
                return 0;
			}
			ENDCG
		}
	}
}
