using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Dissolve : MonoBehaviour
{
   public Material material;

   [Range(0.01f, 1.0f)]
   public float burnSpeed = 0.3f;

   private float burnAmount = 0.0f;
   void Start () {
      if (material == null) {
         Renderer renderer = gameObject.GetComponentInChildren<Renderer>();
         if (renderer != null) {
            material = renderer.material;
         }
      }

      if (material == null) {
         this.enabled = false;
      } else {
         material.SetFloat("_BurnAmount", 0.0f);
      }
   }

   private void Update()
   {
      burnAmount = Mathf.Repeat(Time.deltaTime * burnSpeed, 1.0f);
   }
}
