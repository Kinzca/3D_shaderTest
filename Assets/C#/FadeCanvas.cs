using System;
using UnityEngine;
using UnityEngine.UI;

public class FadeCanvas : MonoBehaviour
{
    public Image fadeImage;
    public Text sampleText;
    
    public float fadeTime = 1.0f;
    private float currentFadeTime = 0.0f;

    private void Start()
    {
        fadeImage.color = new Color(fadeImage.color.r, fadeImage.color.g, fadeImage.color.b, 1f);
        sampleText.color = new Color(sampleText.color.a, sampleText.color.g, sampleText.color.b, 1f);
    }

    private void Update()
    {
        // 根据淡入淡出的状态更新当前淡入淡出时间
        if(currentFadeTime <= fadeTime)
        {
            currentFadeTime += Time.deltaTime;
        }

        // 计算当前的透明度
        float alpha = Mathf.Clamp01(1 - currentFadeTime / fadeTime);
        float textalpha = Mathf.Clamp01(1 - currentFadeTime / fadeTime);
        
        // 设置图片的颜色
        fadeImage.color = new Color(fadeImage.color.r, fadeImage.color.g, fadeImage.color.b, alpha);
        sampleText.color = new Color(sampleText.color.a, sampleText.color.g, sampleText.color.b, textalpha);
        // // 如果淡入淡出时间到达边界，切换淡入淡出状态
        // if (currentFadeTime <= 0.0f)
        // {
        //     fadeIn = true;
        //     currentFadeTime = 0.0f;
        // }
        // else if (currentFadeTime >= fadeTime)
        // {
        //     fadeIn = false;
        //     currentFadeTime = fadeTime;
        // }
    }
}