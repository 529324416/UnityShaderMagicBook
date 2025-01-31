using System;
using System.Collections.Generic;
using UnityEngine;
using Random = UnityEngine.Random;

namespace LakeSimulation
{
    [RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
    [RequireComponent(typeof(BoxCollider))]
    public class WaterMesh : MonoBehaviour
    {
        [SerializeField] private float springConst = 0.023f;
        [SerializeField] private float damping = 0.005f;
        [SerializeField] private float spread = 0.1f;
        [SerializeField] private int width = 32;
        [SerializeField] private int height = 32;
        [SerializeField] private float latticeSize = 0.5f;
        [SerializeField] private float waveScale = 1.0f;
        [SerializeField] private Light mainLight;
        [SerializeField] public bool disableAutoWave = true;
        
        private Mesh mesh;
        private Vector3[] vertices;
        private SimpleWater water;
        private float timer;
        private Material material;
        private BoxCollider boxCollider;
        
        private void Start()
        {
            water = new SimpleWater(width, height, springConst, damping, spread);
            mesh = CreateMeshFromWater(water, Mathf.Max(latticeSize, 0.1f));
            GetComponent<MeshFilter>().mesh = mesh;
            material = GetComponent<MeshRenderer>().sharedMaterial;
            boxCollider = GetComponent<BoxCollider>();
        }

        private void Update()
        {
            var bounds = boxCollider.bounds;
            material.SetVector("_BoundsMin", bounds.min);
            material.SetVector("_BoundsMax", bounds.max);
            if (mainLight != null)
                material.SetMatrix("_SunMatrix", mainLight.transform.localToWorldMatrix);
        }

        private void FixedUpdate()
        {
            // 更新水体状态和网格顶点
            // update water simulation and mesh vertices
            water.Update(Time.fixedDeltaTime);
            mesh.vertices = UpdateWaterMesh(water);
            mesh.RecalculateNormals();
            
            // 每过1-3秒随机设置一个水波
            // set a random wave every 1-3 seconds
            if (disableAutoWave) return;
            if (timer <= 0)
            {
                timer = Random.Range(1f, 3f);
                int x = Random.Range(0, width);
                int y = Random.Range(0, height);
                water.SetOffset(x, y, -Random.value);
            }
            else
            {
                timer -= Time.deltaTime;
            }
        }

        public void RaiseWave(Vector3 positionWS, float intensity)
        {
            var localPos = transform.InverseTransformPoint(positionWS);
            var x = Mathf.FloorToInt(localPos.x / latticeSize);
            var y = Mathf.FloorToInt(localPos.z / latticeSize);
            water.SetOffset(x, y, intensity);
        }

        private Mesh CreateMeshFromWater(SimpleWater water, float latticeSize = 1f)
        {
            var vertexes = new List<Vector3>();
            var triangles = new List<int>();

            for (int x = 0; x < water.width; x++)
            {
                for (int y = 0; y < water.height; y++)
                {
                    var vtx = new Vector3(x * latticeSize, 0, y * latticeSize);
                    vertexes.Add(vtx);
                }
            }
            
            for (int x = 0; x < water.width - 1; x++)
            {
                for (int y = 0; y < water.height - 1; y++)
                {
                    int LB = x * water.height + y;
                    int LT = LB + 1;
                    int RB = (x + 1) * water.height + y;
                    int RT = RB + 1;
                    
                    triangles.Add(LB);
                    triangles.Add(LT);
                    triangles.Add(RT);
                    
                    triangles.Add(LB);
                    triangles.Add(RT);
                    triangles.Add(RB);
                }
            }
            
            var mesh = new Mesh()
            {
                vertices = vertexes.ToArray(),
                triangles = triangles.ToArray(),
            };
            return mesh;
        }
        
        private Vector3[] UpdateWaterMesh(SimpleWater water)
        {
            vertices ??= mesh.vertices;
            for (int x = 0; x < water.width; x++)
            {
                for (int y = 0; y < water.height; y++)
                {
                    var idx = x * water.height + y;
                    var source = vertices[idx];
                    source.y = water.GetOffset(x, y) * waveScale;
                    vertices[idx] = source;
                }
            }

            return vertices;
        }
    }
}