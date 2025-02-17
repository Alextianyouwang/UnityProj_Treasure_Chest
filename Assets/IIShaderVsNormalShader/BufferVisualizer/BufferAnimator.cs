using System.Net.NetworkInformation;
using UnityEngine;
using TriInspector;
using UnityEditor.Localization.Plugins.XLIFF.V12;
using TMPro;
using Unity.VisualScripting;
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

    [Range(0,1)]
    public float GlobalEffect;

    [Range(0,1)]
    public float FloatValue;

    private float _noiseIntensity;

    private int _count = 32;
    private void OnEnable()
    {
       
        _mpbs = new MaterialPropertyBlock[_count];
        

    }
    private void OnDisable()
    {
       // for (int i = 0; i < _count; i++) 
       // {
       //     MeshRenderer r = Anchor.GetChild(i).GetComponent<MeshRenderer>();
       //     _mpbs[i].SetColor("_Tint", OriginalMat.GetColor("_Tint"));
       //     r.SetPropertyBlock(_mpbs[i]);
       //
       //     _mpbs[i] = null;
       // }
    }
    private void SetPropery(float globalIntensity, float globalMask) 
    {
        int counter = 0;
        for (int i = 0; i < _count; i++) 
        {
            MeshRenderer r = Anchor.GetChild(i).GetComponent<MeshRenderer>();
            TextMeshProUGUI gui =  r.transform.GetChild(0).GetComponentInChildren<TextMeshProUGUI>();
            _noiseIntensity = Mathf.PerlinNoise(r.transform.position.z * 100f + Time.time,0.23f);
            float intensity = _noiseIntensity * globalIntensity;
            gui.text = (intensity* 100).ToString(intensity == 0 || intensity == 1?"":"F1");
            gui.fontSize = intensity == 0 || intensity == 1 ? 1 : 0.4f;
            gui.color = Color.Lerp(Color.clear, Color.white, globalMask);
            gui.ForceMeshUpdate();
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

     
            
            c = new Color(c.r * intensity , c.g * intensity, c.b * intensity);
            c = Color.Lerp(OriginalMat.GetColor("_Tint"),c, globalMask);
            _mpbs[i] = new MaterialPropertyBlock();
            _mpbs[i].SetColor("_Tint", c);
            r.SetPropertyBlock(_mpbs[i]);
            

                counter++;
        }
    }

    private void LateUpdate()
    {
        SetPropery(FloatValue,GlobalEffect);
    }
    [Button]
    private void ToggleText(bool value) 
    {
        for (int i = 0; i < _count; i++) 
        {
            Anchor.GetChild(i).GetChild(0).gameObject.SetActive(value);
        }
    }
    [Button]
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
