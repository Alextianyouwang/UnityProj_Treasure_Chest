using UnityEngine;

#if UNITY_EDITOR
using UnityEditor;
#endif

[ExecuteInEditMode]
public class GizmoFormation : MonoBehaviour
{
    [Header("Grid Settings")]
    public int width = 5; // Number of gizmos along X and Z axes
    public float spacing = 1f; // Distance between gizmos

    [Header("Corner Height Offsets")]
    public float BL_Offset = 0f; // Bottom-Left (0,0)
    public float BR_Offset = 0f; // Bottom-Right (width,0)
    public float TL_Offset = 0f; // Top-Left (0,width)
    public float TR_Offset = 0f; // Top-Right (width,width)

    public Vector3[] _spawnPos;

    private float minHeight = -1;
    private float maxHeight = 1;

    private void OnDrawGizmos()
    {
        _spawnPos = new Vector3[width * width];

        // Find min and max height for color interpolation
        minHeight = Mathf.Min(BL_Offset, BR_Offset, TL_Offset, TR_Offset);
        maxHeight = Mathf.Max(BL_Offset, BR_Offset, TL_Offset, TR_Offset);

        for (int x = 0; x < width; x++)
        {
            for (int z = 0; z < width; z++)
            {
                float u = x / (float)(width - 1); // Normalized X position (0 to 1)
                float v = z / (float)(width - 1); // Normalized Z position (0 to 1)

                // Bilinear interpolation for Y height
                float bottom = Mathf.Lerp(BL_Offset, BR_Offset, u);
                float top = Mathf.Lerp(TL_Offset, TR_Offset, u);
                float yOffset = Mathf.Lerp(bottom, top, v);

                Vector3 position = transform.position + new Vector3(x * spacing, yOffset, z * spacing);
                _spawnPos[x * width + z] = position;

                // Color interpolation (red for high, blue for low)
                float heightNormalized = Mathf.InverseLerp(minHeight, maxHeight, yOffset);
                Gizmos.color = Color.Lerp(Color.blue, Color.red, yOffset);

                Gizmos.DrawSphere(position, 0.1f);
            }
        }
    }
}
