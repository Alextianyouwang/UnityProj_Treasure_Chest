using UnityEngine;

public class QuadGridLerp : MonoBehaviour
{
    public int gridSize = 5;
    public float quadSize = 1f;
    public float lerpValue = 0f; // 0 = ladder, 1 = smooth slope
    public float noiseScale = 0.2f;

    private Mesh[,] meshes;
    private Vector3[,] originalPositions;
    private Vector3[,] targetPositions;
    private MeshFilter[,] meshFilters;

    void Start()
    {
        GenerateGrid();
    }

    void Update()
    {
        UpdateLerp();
    }

    void GenerateGrid()
    {
        meshes = new Mesh[gridSize, gridSize];
        originalPositions = new Vector3[gridSize + 1, gridSize + 1];
        targetPositions = new Vector3[gridSize + 1, gridSize + 1];
        meshFilters = new MeshFilter[gridSize, gridSize];

        // Store original positions with gaps, ensuring quads are parallel to global Y-axis
        for (int x = 0; x <= gridSize; x++)
        {
            for (int y = 0; y <= gridSize; y++)
            {
                float noiseHeight = Mathf.PerlinNoise(x * noiseScale, y * noiseScale) * 2f;
                originalPositions[x, y] = new Vector3(x * quadSize, noiseHeight, y * quadSize);
            }
        }

        // Create quads
        for (int x = 0; x < gridSize; x++)
        {
            for (int y = 0; y < gridSize; y++)
            {
                GameObject quad = new GameObject($"Quad_{x}_{y}", typeof(MeshFilter), typeof(MeshRenderer));
                quad.transform.parent = transform;
                quad.transform.position = Vector3.zero;
                MeshFilter mf = quad.GetComponent<MeshFilter>();
                MeshRenderer mr = quad.GetComponent<MeshRenderer>();
                mr.material = new Material(Shader.Find("Standard"));

                meshes[x, y] = new Mesh();
                mf.mesh = meshes[x, y];
                meshFilters[x, y] = mf;
                UpdateQuadMesh(x, y);
            }
        }
    }

    void UpdateLerp()
    {
        for (int x = 0; x <= gridSize; x++)
        {
            for (int y = 0; y <= gridSize; y++)
            {
                Vector3 basePosition = originalPositions[x, y];
                Vector3 snapPosition = basePosition;
                if (x < gridSize && y < gridSize)
                {
                    snapPosition = (originalPositions[x, y] + originalPositions[x + 1, y] + originalPositions[x, y + 1] + originalPositions[x + 1, y + 1]) / 4;
                }
                targetPositions[x, y] = Vector3.Lerp(snapPosition, basePosition, 1 - lerpValue);
            }
        }

        for (int x = 0; x < gridSize; x++)
        {
            for (int y = 0; y < gridSize; y++)
            {
                UpdateQuadMesh(x, y);
            }
        }
    }

    void UpdateQuadMesh(int x, int y)
    {
        Mesh mesh = meshes[x, y];
        Vector3[] vertices = new Vector3[4]
        {
            targetPositions[x, y],
            targetPositions[x + 1, y],
            targetPositions[x, y + 1],
            targetPositions[x + 1, y + 1]
        };

        int[] triangles = new int[] { 0, 2, 1, 2, 3, 1 };
        Vector2[] uv = new Vector2[] { Vector2.zero, Vector2.right, Vector2.up, Vector2.one };
        Vector3[] normals = new Vector3[] { Vector3.up, Vector3.up, Vector3.up, Vector3.up };

        mesh.Clear();
        mesh.vertices = vertices;
        mesh.triangles = triangles;
        mesh.uv = uv;
        mesh.normals = normals;
    }
}