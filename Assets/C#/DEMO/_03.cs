using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class _03 : MonoBehaviour
{
    public void Last()
    {
        SceneManager.LoadScene("3");
    }
    public void Next()
    {
        SceneManager.LoadScene("5");
    }
}
