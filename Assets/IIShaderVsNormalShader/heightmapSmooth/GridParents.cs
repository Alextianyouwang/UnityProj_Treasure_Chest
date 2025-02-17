using System.Collections;
using System.Collections.Generic;
using UnityEngine;
[ExecuteInEditMode]
public class GridParents : MonoBehaviour
{
    public GizmoFormation[] Formation;

    private List<Vector3> _allPositions;
    public void GetVertex() 
    {
        foreach (var position in Formation) 
        {
            Vector3[] vs = position._spawnPos;
            foreach (var v in vs) { 
                _allPositions.Add(v);
            }
        }
    }

    public void LateUpdate()
    {
        foreach (Vector3 v in _allPositions) 
        {
            Mathf.PerlinNoise(v.x, v.z);
        }
    }
}
