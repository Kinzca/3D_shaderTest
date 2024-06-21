using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraRotation : MonoBehaviour
{
    public float rotationSpeed = 5f;
    public float distance;
    public Vector3 offsetY;
    public Transform target;
    public float minAngle = -45f; // 最小旋转角度
    public float maxAngle = 45f; // 最大旋转角度
    public bool limitRotation = true; // 是否限制旋转角度

    private float moveX;

    private void Update()
    {
        moveX += Time.deltaTime * rotationSpeed;

        // 如果限制旋转角度，则在最小角度和最大角度之间进行限制
        if (limitRotation)
        {
            moveX = Mathf.Clamp(moveX, minAngle, maxAngle);
        }

        Quaternion rotation = Quaternion.Euler(0, moveX, 0);

        Vector3 offset = rotation * Vector3.forward * distance;

        transform.position = target.position - offset + offsetY;

        transform.LookAt(target.position);
    }
}