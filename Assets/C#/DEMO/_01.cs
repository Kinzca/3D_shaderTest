using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class _01 : MonoBehaviour
{
    public void Last()
    {
        SceneManager.LoadScene("1");
    }
    public void Next()
    {
        SceneManager.LoadScene("3");
    }
}
