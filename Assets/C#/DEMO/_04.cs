using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class _04 : MonoBehaviour
{
    public void Last()
    {
        SceneManager.LoadScene("4");
    }
    public void Next()
    {
        SceneManager.LoadScene("6");
    }
}
