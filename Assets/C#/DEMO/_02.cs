using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class _02 : MonoBehaviour
{
    public void Last()
    {
        SceneManager.LoadScene("2");
    }
    public void Next()
    {
        SceneManager.LoadScene("4");
    }
}
