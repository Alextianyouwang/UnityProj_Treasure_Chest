using UnityEngine;
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

    public int MaxCount = 10000;
    private void OnEnable()
    {
        _compute_inst = Instantiate(Compute);
        _cb_args = new ComputeBuffer(1, sizeof(uint) * 5, ComputeBufferType.IndirectArguments);
        _cb_position = new ComputeBuffer(MaxCount, sizeof(float) * 3);
        _cb_args.SetData(new uint[] { Mesh.GetIndexCount(0), (uint)MaxCount, Mesh.GetIndexStart(0), Mesh.GetBaseVertex(0), 0 });
        Material.SetBuffer("_PositionBuffer", _cb_position);
        _compute_inst .SetBuffer(1,"_PositionBuffer", _cb_position);
        _compute_inst .SetInt("_Dimension", 32);
        _compute_inst .SetInt("_MaxCount", MaxCount);
        _compute_inst .SetFloat("_Increment", 100 / 99f);
        _compute_inst.SetVector("_Offset", Offset);


    }
    private void LateUpdate()
    {
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






















