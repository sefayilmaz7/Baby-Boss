using System;
using FluffyUnderware.Curvy.Generator.Modules;

[Serializable]
public class RoadEssentialModules
{
    public InputSplinePath path;
    public InputSplineShape pathShape;
    public InputSplineShape railShape;
    public InputGameObject railObjectInput;
    public BuildRasterizedPath rasterPath;
    public CreateMesh createRailMesh;
}