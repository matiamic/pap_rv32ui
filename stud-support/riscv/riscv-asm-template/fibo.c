int fibo(int n)
{
  if (n == 0 || n == 1)
    {
      return n;
    }

  return fibo(n - 2) + fibo(n - 1);
}

int main(int argc, char *argv[])
{
  return fibo(20);
}
