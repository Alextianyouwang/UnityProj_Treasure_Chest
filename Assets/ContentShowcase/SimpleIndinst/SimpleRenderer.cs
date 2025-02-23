using UnityEngine;
[ExecuteInEditMode]
public class SimpleRenderer : MonoBehaviour
{
    public Mesh Mesh;
    public Material Material;
    public ComputeShader Compute;
    private ComputeBuffer _cb_args;
    private ComputeBuffer _cb_position;
    public Vector3 BoundSize;
    private void OnEnable()
    {
        _cb_args = new ComputeBuffer(1, sizeof(uint) * 5, ComputeBufferType.IndirectArguments);
        _cb_position = new ComputeBuffer(10000, sizeof(float) * 3);
        _cb_args.SetData(new uint[] { Mesh.GetIndexCount(0),10000, Mesh.GetIndexStart(0), Mesh.GetBaseVertex(0), 0 });
        Material.SetBuffer("_PositionBuffer", _cb_position);
        Compute.SetBuffer(1,"_PositionBuffer", _cb_position);
        Compute.SetInt("_Dimension", 100);
        Compute.SetInt("_MaxCount", 10000);
        Compute.SetFloat("_Increment", 200 / 99f);
    }
    private void LateUpdate()
    {
        Compute.SetVector("_BotLeft", transform.position);
        Compute.Dispatch(1, Mathf.CeilToInt(10000f / 64f), 1, 1);
        Graphics.DrawMeshInstancedIndirect(Mesh, 0, Material, new Bounds(transform.position,BoundSize), _cb_args);
    }
    private void OnDisable()
    {
        _cb_args.Release();
        _cb_position.Release();
    }
    private void OnDrawGizmos()
    {
        Gizmos.DrawWireCube(transform.position, BoundSize);
    }
}






















