using System.Collections;
using UnityEngine;
using TriInspector;
using UnityEditor.Localization.Plugins.XLIFF.V12;
using System;
[ExecuteInEditMode]
public class SimpleRenderer2 : MonoBehaviour
{
    public Mesh Mesh;
    public Material Material;
    public Vector3 Offset;
    public ComputeShader Compute;
    private ComputeShader _compute_inst;
    private ComputeBuffer _cb_args;
    private ComputeBuffer _cb_position;

    public int MaxCount = 100000;
    private int _accum_amount, _startAmount;
    [Range(0, 1)]
    public float Lerp;

    private bool _canShiftAnimate = true;

    private void OnEnable()
    {
        _startAmount = MaxCount;
        _compute_inst = Instantiate(Compute);
        Initialize();

    }
    private void Initialize()
    {
        _cb_args?.Release();
        _cb_position?.Release();
        _cb_args = new ComputeBuffer(1, sizeof(uint) * 5, ComputeBufferType.IndirectArguments);
        _cb_position = new ComputeBuffer(MaxCount, sizeof(float) * 3);
        _cb_args.SetData(new uint[] { Mesh.GetIndexCount(0), (uint)MaxCount, Mesh.GetIndexStart(0), Mesh.GetBaseVertex(0), 0 });
        Material.SetBuffer("_PositionBuffer", _cb_position);
        _compute_inst.SetBuffer(1, "_PositionBuffer", _cb_position);
        _compute_inst.SetInt("_Dimension", 32);
        _compute_inst.SetInt("_MaxCount", MaxCount);
        _compute_inst.SetFloat("_Increment", 100 / 99f);
        _compute_inst.SetVector("_Offset", Offset);
        _compute_inst.SetFloat("_Lerp", 0);
        _accum_amount = MaxCount;

    }
    [Button]
    public void ShiftIndex()
    {
        StartCoroutine(ShiftIndex((int)((UnityEngine.Random.value - 0.5) * 400), 0.5f, null));
    }
    [Button]
    public void RepeatShiftIndex()
    {
        StartCoroutine(ShiftIndex((int)((UnityEngine.Random.value - 0.5) * 400), 0.5f, RepeatShiftIndex));
    }
    [Button]
    public void SetShiftIndex(int value)
    {
        _canShiftAnimate = true;
        StartCoroutine(ShiftIndex(value, 0.5f,null));
    }
    [Button]
    public void StopShiftIndex()
    {
        _canShiftAnimate = false;
    }

    [Button]
    public void ResetObject()
    {
        StartCoroutine(ShiftIndex( _startAmount - _accum_amount, 0.5f, null));
    }
    private IEnumerator ShiftIndex(int amount, float duration, Action OnNext) 
    {
        float time = 0;
        _accum_amount += amount;
        if (!_canShiftAnimate) 
        {
            StopAllCoroutines();
            yield break;

        }
        while (time < duration) 
        {
            float percentage = time / duration;
            _compute_inst.SetFloat("_Lerp",  percentage);
            _compute_inst.SetInt("_IndexOffset", amount);

            time += Time.deltaTime;
            yield return null;
        }
        MaxCount = _accum_amount;
        _compute_inst.SetInt("_MaxCount", _accum_amount);

        Initialize();
        OnNext?.Invoke();
    }


    private void LateUpdate()
    {
       //_compute_inst.SetFloat("_Lerp", Lerp);
       //_cb_args.SetData(new uint[] { Mesh.GetIndexCount(0), (uint)( MaxCount * Lerp) + 1, Mesh.GetIndexStart(0), Mesh.GetBaseVertex(0), 0 });
        _compute_inst .SetVector("_BotLeft", transform.position);
        _compute_inst.Dispatch(1,Mathf.CeilToInt(MaxCount / 64f), 1, 1);
        Graphics.DrawMeshInstancedIndirect(Mesh, 0, Material, new Bounds(Vector3.zero, Vector3.one * 10101f), _cb_args,0,null,
            UnityEngine.Rendering.ShadowCastingMode.On,true);
    }
    private void OnDisable()
    {
        _cb_args.Release();
        _cb_position.Release();
    }
}






















