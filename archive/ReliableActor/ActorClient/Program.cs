using System;
using System.Threading.Tasks;
using Microsoft.ServiceFabric.Actors;
using Microsoft.ServiceFabric.Actors.Client;
using HelloWorld.Interfaces;

namespace ActorClient
{
    class Program
    {
        static void Main(string[] args)
        {
            IHelloWorld actor = ActorProxy.Create<IHelloWorld>(ActorId.CreateRandom(), new Uri("fabric:/ReliableActor/HelloWorldActorService"));
            Task<string> retval = actor.GetHelloWorldAsync();
            Console.Write(retval.Result);
            Console.ReadLine();
        }
    }
}