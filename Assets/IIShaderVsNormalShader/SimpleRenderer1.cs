using UnityEngine;
[ExecuteInEditMode]
public class SimpleRenderer1 : MonoBehaviour
{
    public Mesh Mesh;
    public Material Material;
    private ComputeBuffer _cb_args;
    private ComputeBuffer _cb_position;
    private void OnEnable()
    {
        _cb_args = new ComputeBuffer(1, sizeof(uint) * 5, ComputeBufferType.IndirectArguments);
        _cb_position = new ComputeBuffer(10000, sizeof(float) * 3);
        _cb_args.SetData(new uint[] { Mesh.GetIndexCount(0), 10000, Mesh.GetIndexStart(0), Mesh.GetBaseVertex(0), 0 });
        Material.SetBuffer("_PositionBuffer", _cb_position);
    }
    private void LateUpdate()
    {
        _cb_position.SetData(CreateFromation_100x100 (transform.position, 200f));
        Graphics.DrawMeshInstancedIndirect(Mesh, 0, Material, new Bounds(Vector3.zero, Vector3.one * 10101f), _cb_args);
    }
    private void OnDisable()
    {
        _cb_args.Release();
        _cb_position.Release();
    }
    public Vector3[] CreateFromation_100x100(Vector3 botLeft, float size)
    {
        Vector3[] arry = new Vector3[10000];
        float increment = size / 99f;
        for (int x = 0; x < 100; x++)
        {
            for (int y = 0; y < 100; y++)
            {
                Vector2 xz = new Vector2(x * increment + botLeft.x, y * increment + botLeft.z);
                float noise = Mathf.PerlinNoise(xz.x, xz.y);
                arry[x * 100 + y] = new Vector3(xz.x, botLeft.y + noise * 3, xz.y);
            }
        }
        return arry;
    }
}
