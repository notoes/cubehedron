﻿Shader "Custom/Ink" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_InkColor ("Ink Color", Color) = (0,0,0,0)
		_InkCutoff ("Ink Cutoff", Float) = 0.5
		_InkRamp ("Ink Ramp", 2D) = "black"
		_NoiseTex ("Noise Tex", 2D) = "white" {}
		_EdgeWobbleFactor ("Edge Wobble Factor", Range(0,1)) = 0.1
		_TurbulenceTex ("Turbulence", 2D) = "white"
		_TurbulenceFactor ("Turbulence Factor", Float) = 0.1
		_PigmentDispertionFactor ("Pigment Dispersion Factor", Float) = 0.1
	}


	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		Cull Back
		ZWrite On
		ColorMask RGB

		CGPROGRAM
		#pragma surface surf Ink
		#pragma target 3.0

		sampler2D _MainTex;
		fixed4 _InkColor;
		fixed _InkCutoff;
		sampler2D _InkRamp;
		sampler2D _NoiseTex;
		fixed _EdgeWobbleFactor;
		sampler2D _TurbulenceTex;
		fixed _TurbulenceFactor;
		fixed _PigmentDispertionFactor;

		struct SurfaceOutputUV
		{
		    fixed3 Albedo;
		    fixed3 Normal;
		    fixed3 Emission;
		    half Specular;
		    fixed Gloss;
		    fixed Alpha;

		    fixed2 uv;
		};

	    half4 LightingInk (SurfaceOutputUV s, half3 lightDir, half3 viewDir, half atten) {
	    	fixed4 c;
	        fixed NdotL = dot (s.Normal, lightDir);

	        // Half-lambert, range 0-1
	        fixed halfLambert = (NdotL*0.5) + 0.5;

	    	fixed noise = tex2D(_NoiseTex,s.uv ).r;
	    	fixed turb = tex2D(_TurbulenceTex,s.uv ).r;

	    	// A random shadow wobble to give more organic edges. [-0.5,0.5]
	    	fixed wobble = (turb-0.5) * _EdgeWobbleFactor;
	    	halfLambert += wobble;

	        // Make the shadows we get from atten brighter.
	    	fixed shadow = (atten+0.5) * 0.9;

	    	// Prefer self-shadowing to atten light shadows
	    	if( halfLambert < _InkCutoff ) {
	    		fixed lNorm = halfLambert*(1/_InkCutoff);
	    		shadow = tex2D( _InkRamp, fixed2(lNorm) );
	    	}

	        // Simulate pigment dispertion with a noise tex to offset uv
	    	fixed pg = (noise-0.5) * _PigmentDispertionFactor;
		    fixed2 uv2 = s.uv + fixed2(pg);

	    	// Simulate ink turbulence by darkening
	        fixed t = tex2D(_TurbulenceTex, uv2 ).r;
	        t -= 0.5;
	        t *= _TurbulenceFactor;

	        shadow += t;

	    	c.rgb = shadow * _InkColor;
	        c.a = s.Alpha;

	    	return c;
	    }


	    half4 LightingInkOld (SurfaceOutputUV s, half3 lightDir, half3 viewDir, half atten) {

	        fixed normalLight = dot (s.Normal, lightDir);

	        // Half-lambert, range 0-1
	        //normalLight = (normalLight*0.5) + 0.5;

	        // Alter the edge of the ink by a noise texture
	        fixed noise = tex2D(_NoiseTex,s.uv ).r;

	        // The higher the factor, the less random variation
	        fixed wobble = (noise-0.5) * _EdgeWobbleFactor;

	        normalLight += wobble;

	        fixed4 c;
	        c.rgb = s.Albedo;
	        c.a = s.Alpha;

	        if( normalLight < _InkCutoff ) {
	        	// Simulate pigment dispertion with a noise tex to offset uv
		        fixed pg = noise * _PigmentDispertionFactor;
		        fixed2 uv2 = s.uv + fixed2(pg);

	        	// Simulate ink turbulence by darkening
	        	fixed t = tex2D(_TurbulenceTex, uv2 ).r;
	        	t -= 0.5;
	        	t *= _TurbulenceFactor;

	        	c.rgb = tex2D( _InkRamp, fixed2(normalLight) );

   				fixed diffView = dot(s.Normal, normalize(viewDir));
		        if( diffView < 0.15 ) {
		        	c.rgb = 0;
	    	    }

	        }

	        // Simple Lambert
	        fixed lightValue = (normalLight * atten * 2);
	        //c.rgb = c.rgb * s.Albedo * _LightColor0.rgb;// * atten * 2;

	       	c.rgb = tex2D( _InkRamp, fixed2(normalLight) );
	    	return c;
	    }


		struct Input {
			float2 uv_MainTex;
		};

		void surf (Input IN, inout SurfaceOutputUV o) {
			half4 c = tex2D (_MainTex, IN.uv_MainTex);
			o.Albedo = c.rgb;
			o.Alpha = c.a;
			o.uv = IN.uv_MainTex;
		}
		ENDCG
	}
	Fallback "VertexLit"
	//FallBack "Diffuse"
}
