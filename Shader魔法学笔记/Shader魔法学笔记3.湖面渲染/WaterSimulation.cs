using UnityEngine;

public class SimpleWater
{
    private struct Spring
    {
        private float acceleration;
        public float velocity;
        public float offset;

        public void Update(float springConst, float damping)
        {
            acceleration = -springConst * offset - damping * velocity;
            velocity += acceleration;
            offset += velocity;
        }
    }

    public readonly int width;
    public readonly int height;
    private readonly float springConst;
    private readonly float damping;
    private readonly float spread;
    private readonly Spring[,] springs;
    
    public SimpleWater(int width, int height, float springConst, float damping, float spread)
    {
        this.width = width;
        this.height = height;
        this.springConst = springConst;
        this.damping = damping;
        this.spread = spread;
        springs = new Spring[width, height];
        for (int x = 0; x < width; x++)
            for (int y = 0; y < height; y++)
                springs[x, y] = new Spring();
    }

    public float GetOffset(int x, int y) =>
        springs[x % width, y % height].offset;

    public void SetOffset(int x, int y, float offset)
    {
        x %= width;
        if (x < 0) return;
        y %= height;
        if (y < 0) return;
        springs[x, y].offset = offset;
    }

    public void Update(float dt)
    {
        // update spring positions
        for (int x = 0; x < width; x++)
        for (int y = 0; y < height; y++)
            springs[x, y].Update(springConst, damping);
            
        // spread forces
        for (int x = 0; x < width; x++)
        {
            for (int y = 0; y < height; y++)
            {
                float force = 0;
                for (int dx = -1; dx <= 1; dx++)
                {
                    for (int dy = -1; dy <= 1; dy++)
                    {
                        if (dx == 0 && dy == 0) continue;
                        int nx = x + dx;
                        int ny = y + dy;
                        if (nx >= 0 && nx < width && ny >= 0 && ny < height)
                        {
                            force += springs[nx, ny].offset - springs[x, y].offset;
                        }
                    }
                }

                float acceleration = force * spread;
                springs[x, y].velocity += acceleration * dt;
            }
        }
    }
}