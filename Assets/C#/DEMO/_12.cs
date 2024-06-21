using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

public class _12 : MonoBehaviour
{
    public Slider dissolveSlider;

    public Material material;
    
    public void Update()
    {
        UpdateShaderDissolve(dissolveSlider.value);
    }

    public void UpdateShaderDissolve(float value) 
    {
        material.SetFloat("_BurnAmount",value );
    }
    
    public void Last()
    {
        SceneManager.LoadScene("12");
    }
    public void Next()
    {
        SceneManager.LoadScene("14");
    }
}
