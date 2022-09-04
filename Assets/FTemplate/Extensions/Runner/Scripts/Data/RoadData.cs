using System;
using FluffyUnderware.Curvy.Generator;
using FluffyUnderware.DevTools;
using UnityEngine;
using UnityEngine.Rendering;

[CreateAssetMenu(fileName = "RoadData", menuName = "RoadGenerator/New Road Data")]
public class RoadData : ScriptableObject
{
    [Header("Path")]
        
    [Range(0,100)]
    public int resolution;
    public bool optimize;
    public ShadowCastingMode castShadows = ShadowCastingMode.Off;
    public bool receiveShadows = false;
    public bool isStatic = true;
    public float crossStart;
    public float crossEnd = 1f;

    [Range(0f,100f)]
    public float angleThreshold;
    public bool hardEdges;
    public CGKeepAspectMode keepAspectUV;
        

    [Header("Road")]
    public Material roadMaterial;
    public Material roadCapMaterial;
    [Layer]
    public int roadLayer;
    public Vector3 roadShapeTranspose;
    public float roadHeight;
    public float roadWidth;

    public bool doRoadPartObjects;
    public GameObject roadStartCapPrefab;
    public GameObject roadEndCapPrefab;

    [Header("Rail")] 
    public bool doRails;
    public float railHeight;
    public float railWidth;

    public Material railMaterial;
    public Material railCapMaterial;
    [Layer]
    public int railLayer;
    public Vector3 railMeshTranspose;


    [Header("Barrier")] 
    public bool doBarrier;
    public GameObject barrier;
    public float barrierSpacing;
    public Vector3 translation;
}