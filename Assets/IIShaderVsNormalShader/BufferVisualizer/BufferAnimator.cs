using System.Net.NetworkInformation;
using UnityEngine;

[ExecuteInEditMode]
public class BufferAnimator : MonoBehaviour
{
    public GameObject BufferCube;
    public Transform[] Processors;
    public Material OriginalMat;
    private GameObject[] _bufferCubes;
    private Transform[] _spawnedCubes;
    private MaterialPropertyBlock[] _mpbs; 
    public Transform Anchor;
    private int _count = 32;
    private void OnEnable()
    {
        //SpawnCubes();
        _mpbs = new MaterialPropertyBlock[_count];
        SetPropery();

    }
    private void OnDisable()
    {
        for (int i = 0; i < _count; i++) 
        {
            MeshRenderer r = Anchor.GetChild(i).GetComponent<MeshRenderer>();
            _mpbs[i].SetColor("_Tint", OriginalMat.GetColor("_Tint"));
            r.SetPropertyBlock(_mpbs[i]);

            _mpbs[i] = null;
        }
    }
    private void SetPropery() 
    {
        int counter = 0;
  
        for (int i = 0; i < _count; i++) 
        {
            MeshRenderer r = Anchor.GetChild(i).GetComponent<MeshRenderer>();
            Color c = Color.white;
            if (i % 3 == 0) 
            {
                counter = 0;
            }
            if (counter == 0)
                c = Color.red;
            else if (counter == 1)
                c = Color.green;
            else if (counter == 2)
                c = Color.blue;
            _mpbs[i] = new MaterialPropertyBlock();
            _mpbs[i].SetColor("_Tint", c);
            r.SetPropertyBlock(_mpbs[i]);
            

                counter++;
        }
    }
    private void SpawnCubes()
    {
        _bufferCubes = new GameObject[_count];
        
        for (int i = 0; i < _count; i++)
        {
            _bufferCubes[i] = Instantiate(BufferCube);
            _bufferCubes[i].transform.position = Anchor.transform.position + new Vector3(0, 0, i * 100 / 99f);
            _bufferCubes[i].transform.parent = Anchor;
        }
        print ("Spawn")
;
    }
}
