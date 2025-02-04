using Unity.Mathematics;
using UnityEngine;


[ExecuteInEditMode]
public class TangentVisualizer : MonoBehaviour
{
    	public float offset = 0.01f;
	public float scale = 0.1f;

    public GameObject Plane;
	public Texture2D Tangent;
	public ComputeShader Visualizer;

	public Mesh Mesh;
	public Material Material;
	private MaterialPropertyBlock _mpb;

	public Material TangentDisplayMat;
	public Material ObjectDisplayMat;

	public struct InstanceData 
	{
      public   Vector3 _pos;
      public  Vector3 _dir;
    }

	InstanceData[] _start;
	InstanceData[] _end;

	ComputeBuffer _cb_start;
	ComputeBuffer _cb_end;
	ComputeBuffer _cb_animation;
	ComputeBuffer _cb_args;

	[Range(0, 1)]
	public float Blend;

    [Range(0, 1)]
    public float Lerp;
    private void OnEnable()
    {
		GetVertexGUI();
		SetupCompute();

    }

    private void OnDisable()
    {
		_cb_start = null;
		_cb_end = null;
		_cb_animation = null;
		_cb_args = null;
    }
    private void GetVertexGUI() 
	{
        if (Plane == null)
            return;

        if (Tangent == null)
            return;

        MeshFilter filter = GetComponent<MeshFilter>();
		if (filter == null)
			return;

        Mesh mesh = filter.sharedMesh;
		if (mesh == null)
			return;
        Vector2[] uvs = mesh.uv;
        Bounds b = Plane.GetComponent<MeshRenderer>().bounds;
        Vector3 botLeftCorner = b.center - b.extents;

		_start = new InstanceData[uvs.Length];
		_end = new InstanceData[uvs.Length];

        Vector3[] vertices = mesh.vertices;
        Vector3[] normals = mesh.normals;
        Vector4[] tangents = mesh.tangents;

        for (int i = 0; i < mesh.vertexCount; i++)
        {
            Vector2 uv = uvs[i];
            Vector3 pos = botLeftCorner + new Vector3((1-uv.x) * b.extents.x * 2, uv.y * b.extents.y * 2,0 );

            Color tangentSample = Tangent.GetPixelBilinear(uv.x, uv.y);
            Vector3 dirTS = new Vector3(tangentSample.r * 2 -1, tangentSample.g * 2 - 1, tangentSample.b).normalized;
			float3 dirTS_float3 = dirTS;

            Vector3 tangent = new Vector3(tangents[i].x, tangents[i].y, tangents[i].z);
			Vector3 bitangents = Vector3.Cross(normals[i], tangent) * tangents[i].w;
			float3x3 tangentToWorld = new float3x3(tangent, bitangents, normals[i]);
		

            Vector3  startDir = Vector3.Slerp(Vector3.forward, dirTS, Blend);

			Vector3 finalWorldNormal = dirTS.x * tangent+
                    dirTS.y * bitangents +
                    dirTS.z * normals[i];


            Vector3 endDir = Vector3.Slerp(transform.TransformDirection(normals[i]),
                transform.TransformDirection(finalWorldNormal.normalized) , Blend);

            _start[i] = new InstanceData { 
				_pos = pos,
				_dir = startDir,
            };

			_end[i] = new InstanceData
            {
                _pos = transform.TransformPoint( vertices[i]),
                _dir = endDir
            };
        }
    }
	private void SetupCompute() 
	{
		if (Visualizer == null)
			return;
        if (Mesh == null)
            return;
        _cb_start = new ComputeBuffer(_start.Length, sizeof(float) * 6);
		_cb_end = new ComputeBuffer(_start.Length, sizeof(float) * 6);
		_cb_animation = new ComputeBuffer(_start.Length, sizeof(float) * 6);


		_cb_args = new ComputeBuffer(5, sizeof(uint), ComputeBufferType.IndirectArguments);
		_cb_args.SetData(new uint[] {
			Mesh.GetIndexCount(0),
            (uint)_start.Length,
			Mesh.GetIndexStart(0),
            Mesh.GetBaseVertex(0),
            0,
        });


        _cb_start.SetData(_start);
        _cb_end.SetData(_end);
        Visualizer.SetBuffer(0, "_StartBuffer", _cb_start);
        Visualizer.SetBuffer(0, "_EndBuffer", _cb_end);
        Visualizer.SetBuffer(0, "_AnimBuffer", _cb_animation);
		Visualizer.SetInt("_TotalInstance", _start.Length);


		_mpb = new MaterialPropertyBlock();
		_mpb.SetBuffer("_AnimBuffer", _cb_animation);

    }

    private void LateUpdate()
    {
		if (Mesh == null)
			return;
		if (Material == null)
			return;

		TangentDisplayMat.SetFloat("_Blend", Blend);
		ObjectDisplayMat. SetFloat("_Blend", Blend);
		GetVertexGUI();

        _cb_start.SetData(_start);
        _cb_end.SetData(_end);
        Visualizer.SetBuffer(0, "_StartBuffer", _cb_start);
        Visualizer.SetBuffer(0, "_EndBuffer", _cb_end);
        Visualizer.SetBuffer(0, "_AnimBuffer", _cb_animation);

        Visualizer.SetFloat("_Lerp", Lerp);
        Visualizer.Dispatch(0, Mathf.CeilToInt(_start.Length / 64), 1, 1);
		Graphics.DrawMeshInstancedIndirect(Mesh, 0, Material, new Bounds(Vector3.zero, Vector3.one * 10000), _cb_args, 0, _mpb);

    }
    void ShowTangentSpace (Mesh mesh) {
		Vector3[] vertices = mesh.vertices;
		Vector3[] normals = mesh.normals;
        Vector4[] tangents = mesh.tangents;
	//	mesh.GetUVs(0, uvs.ToList());
		for (int i = 0; i < vertices.Length; i++) {
			ShowTangentSpace(
				transform.TransformPoint(vertices[i]),
				transform.TransformDirection(normals[i]),
                transform.TransformDirection(tangents[i]),
                tangents[i].w
			);
		}
	}

	//public async void MapAnimataion(Mesh mesh) 
	//{
	//
	//
    //    float percentage = 0;
	//	Vector3[] initialPos = new Vector3[uvs.Length];
	//	Vector3[] initialDir = new Vector3[uvs.Length];
	//	Vector3[] finalPos = mesh.vertices;
	//	Vector3[] finalDir = mesh.normals;
	//	finalPos = finalPos.Select(x => transform.TransformPoint(x)).ToArray();
	//	finalDir = finalDir.Select(x => transform.TransformDirection(x)).ToArray();
	//	GetVertexGUI();
    //    for (int i = 0; i < uvs.Length; i++)
    //    {
	//		//initialPos[i] = VertexGUIPos[i];
	//		//initialDir[i] = VertexGUIDir[i];
	//		//
    //    }
    //    while (percentage <= 1)
	//	{
	//		percentage += Time.deltaTime * 0.2f;
	//
	//
	//		for (int i = 0; i < uvs.Length; i++) 
	//		{
	//			Vector3 animatedPos = Vector3.Lerp(initialPos[i], finalPos[i], percentage);
	//			Vector3 animatedDir = Vector3.Slerp(initialDir[i], finalDir[i], percentage);
	//
	//		//VertexGUIPos[i] = animatedPos;
	//		//VertexGUIDir[i] = animatedDir;
	//		}
    //            await Task.Yield();
	//
    //    }
    //}
	//
	//

    void ShowTangentSpace (Vector3 vertex, Vector3 normal, Vector3 tangent, float binormalSign) {
	//	vertex += normal * offset;
	//	Gizmos.color = Color.green;
	//	Gizmos.DrawLine(vertex, vertex + normal * scale);
	//	Gizmos.color = Color.red;
	//	Gizmos.DrawLine(vertex, vertex + tangent * scale);
	//
    //   Vector3 binormal = Vector3.Cross(normal, tangent) * binormalSign;
	//	Gizmos.color = Color.blue;
	//	Gizmos.DrawLine(vertex, vertex + binormal * scale);
	}
}
