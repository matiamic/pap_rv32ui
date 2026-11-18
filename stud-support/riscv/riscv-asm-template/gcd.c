int gcd(int a, int b)
{
  while (a != b)
    {
      if (a > b)
        {
          a = a - b;
        }
      else if (b > a)
        {
          b = b - a;
        }
    }

  return a;
}

int main(int argc, char *argv[])
{
  return gcd(252, 105);
}
