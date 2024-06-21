using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class Main : MonoBehaviour
{
    public void Next()
    {
        SceneManager.LoadScene("2");
    }

    public void Last()
    {
        Application.Quit();
    }
}