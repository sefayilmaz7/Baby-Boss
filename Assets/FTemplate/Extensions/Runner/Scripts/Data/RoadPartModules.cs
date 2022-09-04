using System;
using FluffyUnderware.Curvy.Generator.Modules;

[Serializable]
public class RoadPartModules
{
    public BuildShapeExtrusion roadExtrusion;
    public BuildShapeExtrusion railLExtrusion;
    public BuildShapeExtrusion railRExtrusion;

    public ModifierTRSShape roadShapeTrs;
    public ModifierTRSShape railRTrs;
    public ModifierTRSShape railLTrs;

    public BuildVolumeMesh roadMesh;
    public BuildVolumeMesh railLMesh;
    public BuildVolumeMesh railRMesh;

    public BuildVolumeSpots barrierLSpots;
    public BuildVolumeSpots barrierRSpots;
        
    public BuildVolumeCaps roadCaps;
    public BuildVolumeCaps railLCaps;
    public BuildVolumeCaps railRCaps;
    
    public CreateMesh createRoadMesh;
    public CreateGameObject railObjectLCreate;
    public CreateGameObject railObjectRCreate;
}