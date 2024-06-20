using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FractureManager : MonoBehaviour
{
    
    public void Explode() 
    {
        Rigidbody[] childs = new Rigidbody[transform.childCount] ;
        Vector3 averagePos = Vector3.zero ;
        for (int i = 0; i < transform.childCount; i++) 
        {
            childs[i] = transform.GetChild(i).GetComponent<Rigidbody>();
            childs[i].isKinematic = false;
            averagePos += transform.GetChild(i).position;
        }
        averagePos /= transform.childCount;
        foreach (Rigidbody rb in childs) 
        {
            Vector3 direction = ( rb.position - averagePos).normalized;
            rb.AddForce(direction * 30, ForceMode.Impulse);
        }
    }
}
