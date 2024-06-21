using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class _05 : MonoBehaviour
{
    public void Last()
    {
        SceneManager.LoadScene("5");
    }
    public void Next()
    {
        SceneManager.LoadScene("7");
    }
}
