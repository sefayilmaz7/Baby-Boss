using FluffyUnderware.Curvy;
using UnityEngine;

public class PathPart : GeneratorPartBase
{
    [SerializeField] private PathPartData pathData;
    public PathPartData Data => pathData;
    
    [SerializeField, ReadOnly] private PathGenerator pathGenerator;
    [SerializeField, ReadOnly] private CurvySpline spline;
    [SerializeField, ReadOnly] private CurvySplineSegment[] controlPoints;
    [SerializeField, ReadOnly] private int index;


    private Quaternion _right = Quaternion.Euler(0f,90f,0f);
    private Quaternion _left = Quaternion.Euler(0f,-90f,0f);

    public void Init(CurvySpline curvySpline, int indexOfPart, PathPartData pathPartData, PathGenerator generator, ref Vector3 currentDirection)
    {
        spline = curvySpline;
        pathGenerator = generator;
        pathData = new PathPartData();
        pathData.Copy(pathPartData);

        UpdatePart(ref currentDirection, indexOfPart);
    }

    public void UpdatePart(ref Vector3 currentDirection, int indexOf)
    {
        index = indexOf;

        if (index != 0 && pathData.direction == PathDirection.Forward)
        {
            pathData.direction = PathDirection.Left;
        }
        
        var nextDirection = pathData.direction switch
        {
            PathDirection.Left => (_left * currentDirection).Round(),
            PathDirection.Right => (_right * currentDirection).Round(),
            _ => currentDirection
        };
        
        
        if (index == 0)
        {
            pathData.direction = PathDirection.Forward;

            if (controlPoints == null)
            {
                controlPoints = new CurvySplineSegment[2];
                if (spline.ControlPointsList.Count == 2)
                {
                    controlPoints[0] = spline.ControlPointsList[0];
                    controlPoints[1] = spline.ControlPointsList[1];
                }
                else
                {
                    controlPoints = spline.Add(Vector3.zero, Vector3.zero);
                }
            }
            
            var lastSegmentPosition = Vector3.zero;
            var firstSegmentPosition = Vector3.zero;

            var segmentPosition = lastSegmentPosition + (currentDirection * pathData.distance);

            controlPoints[0].SetPosition(firstSegmentPosition);
            controlPoints[1].SetPosition(segmentPosition);
            
            
            controlPoints[0].HandleOut = Vector3.zero;
            controlPoints[0].HandleIn = Vector3.zero;
            controlPoints[1].HandleOut = Vector3.zero;
            controlPoints[1].HandleIn = Vector3.zero;
        }
        else
        {
            var lastSegment = spline.ControlPointsList[(index * 2) - 1];
            lastSegment.AutoHandleDistance = 0f;
            lastSegment.AutoHandles = false;
            lastSegment.HandleOut = currentDirection * pathData.turnLenght / 2f;
            lastSegment.HandleIn = Vector3.zero;

            var firstSegmentPos = lastSegment.transform.position + ((currentDirection + nextDirection) * pathData.turnLenght);
            var secondSegmentPos = firstSegmentPos + (nextDirection * pathData.distance);

            if (controlPoints == null)
            {
                controlPoints = new CurvySplineSegment[2];
                controlPoints[0] = spline.Add(firstSegmentPos, Space.World);
                controlPoints[1] = spline.Add(secondSegmentPos, Space.World);
            }
            else
            {
                controlPoints[0].SetPosition(firstSegmentPos);
                controlPoints[1].SetPosition(secondSegmentPos);
            }

            controlPoints[0].AutoHandleDistance = 0f;
            controlPoints[0].AutoHandles = false;
            controlPoints[0].HandleIn = -nextDirection * pathData.turnLenght / 2f;
            controlPoints[0].HandleOut = Vector3.zero;
        }

        currentDirection = nextDirection;
    }

    public void Delete()
    {
        foreach (var controlPoint in controlPoints)
        {
            spline.Delete(controlPoint,true);
        }
        
        spline.Refresh();

        DestroyImmediate(this);
    }
    
    public override void DeletePart()
    {
        pathGenerator.Delete(this);
    }

    public float GetDistance(int index)
    {
        return controlPoints[index].Distance;
    }
}

