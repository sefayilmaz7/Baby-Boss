using System;
using System.Collections.Generic;
using UnityEngine;

public class Sequence : IStep, ITimer
{
    public bool IsComplete { get; private set; }
    public bool IsRunning { get; private set; }
    public bool Stopped { get; private set; }

    private List<IStep> _Steps = new List<IStep>();

    private int _CurrentIndex = 0;

    private IStep CurrentStep {
        get {
            return _CurrentIndex < _Steps.Count ? _Steps[_CurrentIndex] : null;
        }
    }

    public void Start()
    {
        _CurrentIndex = 0;
        IsRunning = true;
        IsComplete = false;
        CurrentStep.Start();
    }

    public void Tick(float deltaTime)
    {
        if (!IsRunning || IsComplete) return;

        if (!CurrentStep.IsComplete)
        {
            CurrentStep.Tick(deltaTime);
        }
        else
        {
            _CurrentIndex++;

            if (_CurrentIndex >= _Steps.Count)
                IsComplete = true;
            else
                CurrentStep.Start();
        }
    }

    public void Stop()
    {
        _CurrentIndex = _Steps.Count;
        IsRunning = false;
        IsComplete = false;
        Stopped = true;
    }

    public void Pause()
    {
        IsRunning = false;
    }

    public void Resume()
    {
        IsRunning = true;
        Stopped = false;
    }

    public void Restart()
    {
        _CurrentIndex = 0;
        IsRunning = true;
        IsComplete = false;
        CurrentStep.Start();
    }

    public void AddStep(IStep step)
    {
        if (IsRunning)
        {
            throw new InvalidOperationException("INVALID_SEQUENCE_OP");
        }

        _Steps.Add(step);
    }

    public void ClearSteps() { }
}