# WWDC 2019 Session 613: Ray Tracing with Metal

**Speakers:** Sean James, GPU Software Engineer. Wayne Lister, GPU Software Engineer. Matt Kaplan, GPU Software Engineer.

**Session page:** [developer.apple.com/wwdc19/613](https://developer.apple.com/wwdc19/613)

This is a frame-by-frame, slide-by-slide transcription of the 2019 Metal ray tracing session. The talk has three parts. Sean walks through the fundamentals of the `MPSRayIntersector` pipeline, dynamic scenes, and the new `MPSSVGF` denoiser. Wayne covers practical use cases: hard shadows, soft shadows, ambient occlusion, and the sampling strategies that make one ray per pixel actually work. Matt finishes with global illumination, memory and ray lifetime management, and Xcode debugging. At the end Wayne returns for the live multi-GPU tram demo and the tile distribution scheme used on Mac Pro.

---

## Title and Introduction

![](assets/2019_613_page-001.png)

![](assets/frame_00001.jpg)

![](assets/frame_00002.jpg)

Sean takes the stage.

> "Good morning everyone. My name is Sean and I'm an engineer on Apple's GPU Software Team. In this session we're going to talk about Ray Tracing."

![](assets/frame_00004.jpg)

![](assets/frame_00006.jpg)

## What Is Ray Tracing?

![](assets/2019_613_page-002.png)

The opening slide introduces the topic with a rendered Cornell Box image. The caption reads "Tracing a ray's path as it interacts with a scene." The Cornell Box shown throughout this intro is a classic ray tracing test scene: a room with two solid colored walls, a white back wall, and geometric objects casting and receiving light.

Sean walks through the core intuition.

> "So, let's first review what Ray Tracing is. Ray Tracing applications are based on tracing the paths the rays take as they interact with a scene."

![](assets/2019_613_page-003.png)

The same slide, animated to show the next beat of the explanation.

![](assets/frame_00010.jpg)

![](assets/frame_00012.jpg)

### Applications of Ray Tracing

![](assets/2019_613_page-004.png)

A bulleted list expands the scope of ray tracing beyond rendering:

- Rendering
- Audio and physics simulation
- Collision detection
- AI and pathfinding

> "Ray Tracing has applications in rendering, audio, physics simulation, and more."

![](assets/frame_00015.jpg)

### Ray Tracing in Offline Rendering

![](assets/2019_613_page-005.png)

The scene switches to the Sponza Atrium, a high-polygon architectural test model originally published by Crytek, ray traced with Metal. The slide lists the effects offline renderers use ray tracing for:

- Reflections and refraction
- Shadows
- Ambient occlusion
- Global illumination

> "In particular Ray Tracing is often used in offline rendering applications to simulate individual rays of light bouncing around a scene. This allows these applications to render photo realistic reflections, refractions, shadows, global illumination, and more."

![](assets/frame_00018.jpg)

### Ray Tracing in Real-Time

![](assets/2019_613_page-006.png)

The slide pivots to the real-time case with a single new word: "Dynamic scenes."

> "Recently, Ray Tracing has also started to be used in real-time applications such as games. And this actually introduces some new requirements. First, in real-time applications objects tend to move around. So, we need to be able to support both camera and object motion."

![](assets/2019_613_page-007.png)

"Performance" is added to the list.

> "Second, performance is now even more critical. This means that the ray intersection itself has to be as efficient as possible and we also have to make effective use of our limited ray budget."

![](assets/2019_613_page-008.png)

"Denoising" appears.

> "Finally, even with these techniques we won't be able to cast enough rays to remove all the noise. So, we need a sophisticated noise reduction strategy. Fortunately, Metal has built in support for Ray Tracing and Denoising. So, it's easy to get started."

![](assets/frame_00024.jpg)

---

## Ray Tracing Pipeline with Metal

![](assets/2019_613_page-009.png)

Title card: "Ray Tracing with Metal." Sean begins walking through the canonical ray tracing pipeline, building it up box by box.

![](assets/2019_613_page-010.png)

The first box appears: "Generate Rays."

> "So, if you look at a typical Ray Tracing application, they all follow roughly the same outline. First, we generate some rays. Each ray is defined by its origin point and its direction vector."

![](assets/2019_613_page-011.png)

"Intersect with Scene" is added, connected to "Generate Rays" by an arrow labeled "Rays."

> "Those rays are then intersected against the geometry in the scene, which is usually made of triangles."

![](assets/2019_613_page-012.png)

A third stage, "Shading," appears, fed by an "Intersections" arrow. Its output arrow points to a "Image" label.

> "The intersection data could just be the distance to the intersection point, but it typically includes additional data such as the index of the triangle that was hit and the very center coordinates of the intersection point. The next step consumes the intersection results. For example, in a rendering application this is typically a shading step which outputs an image."

![](assets/2019_613_page-013.png)

A feedback arrow, "Additional Rays," loops from Shading back to the ray generation step.

> "And this step may also generate additional rays, so we repeat this process however many times we need until we're done. Applications typically intersect millions of rays with the scene every frame. And this core intersection step is common to all Ray Tracing applications. So, this intersection step is what we accelerate in Metal."

![](assets/2019_613_page-014.png)

The same diagram, with the Intersect box emphasized.

![](assets/frame_00030.jpg)

---

## MPSRayIntersector

![](assets/2019_613_page-015.png)

Sean transitions to the Metal API that makes this possible.

> "Last year, we introduced the MPSRayIntersector API, which is part of the Metal performance shaders framework. This API accelerates ray intersection on the GPU on all of our Mac and iOS devices."

![](assets/2019_613_page-016.png)

The slide cross-references last year's talk: "Metal for Ray Tracing Acceleration, WWDC 2018."

![](assets/2019_613_page-017.png)

A new box appears: "Ray Buffer." The slide describes how the intersector consumes batches of rays in a Metal buffer.

> "At a high level, this API takes in batches of rays through a Metal buffer."

![](assets/2019_613_page-018.png)

An "Intersection Buffer" appears on the right. The text adds: "Returns one intersection per ray."

> "It finds the closest intersection along each ray and returns the results in another buffer."

![](assets/2019_613_page-019.png)

"Command Buffer" is added below, with the note "Encodes into a Metal command buffer."

> "And all of this work is encoded into a Metal commandBuffer at the point in your application where you'd like to do intersection testing."

![](assets/frame_00036.jpg)

### Acceleration Structures

The next sequence of slides reveals a growing diagram piece by piece.

![](assets/2019_613_page-020.png)

![](assets/2019_613_page-021.png)

![](assets/2019_613_page-022.png)

![](assets/2019_613_page-023.png)

![](assets/2019_613_page-024.png)

![](assets/2019_613_page-025.png)

![](assets/2019_613_page-026.png)

Over these build-up slides Sean describes the acceleration structure, a spatial hierarchy that lets the intersector skip triangles that cannot possibly be hit.

> "Much of the speed up comes from building a data structure we call an acceleration structure. This data structure recursively partitions triangles in space so that we can quickly eliminate triangles which cannot possibly intersect a given ray during the intersection search."

![](assets/2019_613_page-027.png)

The slide now shows the full layout: Ray Buffer feeding the Intersector, Intersection Buffer coming out, an Acceleration Structure attached from below, and the Vertex Buffer feeding the acceleration structure.

> "Build an acceleration structure over triangles in a vertex buffer."

![](assets/2019_613_page-028.png)

Next bullet: "Pass acceleration structure to intersector."

> "Metal takes care of building this data structure for you. All you have to do is specify when you'd like to build the acceleration structure, then simply pass it to the intersector for intersection testing."

![](assets/2019_613_page-029.png)

A new bullet this year: "Now builds on the GPU."

> "Now, building this data structure is typically a fixed cost paid when your app starts up. In last year's version of the API this data structure was always built on the CPU. This year, we've moved the acceleration structure build to the GPU, which can significantly reduce the startup cost. And even better, the GPU will be used automatically whenever possible. So, you don't need to do anything to see the speed up in your applications."

![](assets/frame_00042.jpg)

### Putting the Pipeline Together

![](assets/2019_613_page-030.png)

Empty canvas.

![](assets/2019_613_page-031.png)

"Generate Rays" reappears, producing a Ray Buffer.

> "So, like I said, we'll start by generating rays. This is typically done using a compute kernel, but it could also be done from a fragment shader or really any mechanism that can write to a Metal buffer."

![](assets/2019_613_page-032.png)

The Intersector appears, consuming the Ray Buffer and producing an Intersection Buffer.

> "We then pass the ray buffer to the intersector. It'll find the intersections and return the result in our intersection buffer."

![](assets/2019_613_page-033.png)

Acceleration Structure and Vertex Buffer appear below.

> "And remember that to use the intersector we need to provide an acceleration structure. We can often build this just one and reuse it many times."

![](assets/2019_613_page-034.png)

A Shading stage is added, outputting an Image.

> "Finally, we'll launch one last compute kernel which will use the intersection data to write a shaded image into a texture."

![](assets/2019_613_page-035.png)

The full diagram, showing the feedback loop from Shading back into the Ray Buffer for iterative refinement.

> "And this compute kernel can also write additional rays back into the ray buffer for iterative applications."

![](assets/frame_00048.jpg)

---

## Ray Tracing in AR Quick Look

![](assets/2019_613_page-036.png)

Sean introduces the first case study.

> "So, let's see how this works in a real application. For this example, we'll talk about how Ray Tracing is being used in AR Quick Look."

![](assets/2019_613_page-037.png)

The robot model used throughout AR Quick Look demos.

![](assets/2019_613_page-038.png)

Cross-reference: "Advances in AR Quick Look, WWDC 2019."

> "AR Quick Look was introduced last year and allows you to preview 3D assets in augmented reality. We talked a lot about AR Quick Look in this morning's session. So, I'd encourage you to watch that talk as well."

![](assets/2019_613_page-039.png)

The robot appears in an AR scene. Sean narrates what ray tracing buys here.

> "For this talk, we'll focus on how AR Quick Look is using Ray Tracing to render an Ambient Occlusion effect."

![](assets/2019_613_page-040.png)

![](assets/2019_613_page-041.png)

![](assets/2019_613_page-042.png)

![](assets/2019_613_page-043.png)

The animation shows the robot with and without ambient occlusion. With AO enabled, a soft contact shadow forms under the robot's legs on the floor.

> "Ambient Occlusion computes an approximation of how much light can reach each point in the scene. So, this results in the darkening of the ground underneath the robot model as well as soft contact shadows between the robot's legs and the ground. The effect is somewhat subtle, but if we turn it off, we can see that it actually goes a long way towards grounding the robot in the scene. And this is really important for AR applications to prevent objects from looking like they're floating above the ground."

![](assets/2019_613_page-044.png)

![](assets/2019_613_page-045.png)

Sean moves to a fish model swimming through the scene.

> "In last year's version of AR Quick Look, the shadows are actually precomputed, so they wouldn't move as objects moved around. This year, we've used Metal support for dynamic scenes to render these shadows in real time. So now as objects move their shadows will move with them. And this even works for deforming objects such as skinned models. We can see the shadows follow the motions of the fish as it swims around the scene."

![](assets/frame_00054.jpg)

![](assets/frame_00060.jpg)

---

## Dynamic Scenes

![](assets/2019_613_page-046.png)

Sean introduces the three animation types the ray tracer must support.

> "So, what we just saw actually has three types of animation going on. If we were just using the rasterizer, we'd simply rasterize the triangles in their new position. But because we're using Ray Tracing, we need to maintain an acceleration structure."

![](assets/2019_613_page-047.png)

The slide lists:

- Camera movement

![](assets/2019_613_page-048.png)

- Camera movement
- Vertex animation

![](assets/2019_613_page-049.png)

- Camera movement
- Vertex animation
- Rigid body animation

> "The first type of animation is simple camera movement. And this is movement due to just moving the iPad around. We don't need to update the acceleration structure just because the cameras moved. So, we actually get this type of animation for free. We can simply start firing rays from the new camera position. The other two types of animation do require updating the acceleration structure. So, the first is Vertex Animation. This could be skinned models like the fish, but it could also be plants blowing in the wind, cloth, or other types of deformation. Metal includes a special acceleration structure update mechanism optimized for cases like this. And the last type of animation is rigid body animation. This is where objects can move, rotate, and scale, but otherwise completely maintain their shape."

![](assets/frame_00066.jpg)

### Vertex Animation

![](assets/2019_613_page-050.png)

![](assets/2019_613_page-051.png)

![](assets/2019_613_page-052.png)

![](assets/2019_613_page-053.png)

The slides build the concept. "Deformation and skinned animation." Bullets appear in sequence:

- Need to update acceleration structure
- Objects tend to retain their shape

> "So, let's first talk about Vertex Animation. As the geometry changes, we need to update the acceleration structure. We could rebuild it from scratch every frame, but we can actually do better. In Vertex Animation use cases objects tend to mostly retain their shape. For example, a character's hands will stay connected to their arms. Their arms will stay connected to their body and so on. So, the spatial hierarchy encoded into the acceleration structure is mostly still valid. It just needs to be adjusted to the new geometry."

### Refitting Animation

The following five slides walk through the refitting concept visually: triangles moving, bounding boxes no longer fitting them, and the boxes being snapped back from the leaves up.

![](assets/2019_613_page-054.png)

![](assets/2019_613_page-055.png)

![](assets/2019_613_page-056.png)

![](assets/2019_613_page-057.png)

![](assets/2019_613_page-058.png)

> "So, here's the acceleration structure we saw earlier. If the triangles move, we can see that the bounding boxes no longer line up with the triangles. But the tree structure itself mostly still makes sense. So rather than rebuild it from scratch, we can simply snap the bounding boxes to the new triangle positions from bottom to top. We call this operation Refitting."

![](assets/frame_00072.jpg)

### Refitting Properties

![](assets/2019_613_page-059.png)

The slide reads: "Much faster than building from scratch." A timeline below shows two frames, each with stages: Update Vertices, Refit, Intersect.

> "As we can see, this still results in a valid acceleration structure, but it's much faster than building from scratch because we can reuse the existing tree."

![](assets/2019_613_page-060.png)

A new line appears: "Runs on the GPU."

> "This also runs entirely on the GPU, which makes it even faster, but also means that we can safely encode a Refitting operation after say a compute kernel which updates the vertices."

![](assets/2019_613_page-061.png)

"Can't add or remove geometry" is added.

> "The downside is that we can't add or remove any geometry because the tree will still encode references to the old geometry."

![](assets/2019_613_page-062.png)

"Potentially degrades acceleration structure quality" is added.

> "This also potentially degrades the acceleration structures quality which can impact Ray Tracing performance. This is because the triangles were originally partitioned using a set of futuristics which won't be accurate after the triangles move. The impact is usually minor, but extreme cases like teleporting geometry could cause performance problems. Nonetheless, this works great for typical deformation and character skinning use cases."

### Refitting Code

![](assets/2019_613_page-063.png)

Enable refitting before building:

```swift
accelerationStructure.usage = .refit
```

![](assets/2019_613_page-064.png)

Encode refit operation:

```swift
accelerationStructure.usage = .refit


accelerationStructure.encodeRefit(commandBuffer: commandBuffer)
```

> "First, before we build the accelerations structure, we need to enable support for Refitting. And note that just enabling Refitting is enough to reduce the acceleration structure's quality. So definitely only turn this on if you really need to refit the acceleration structure. Then we simple call encodeRefit into a Metal commandBuffer. And that's all we need to do for Vertex Animation."

![](assets/frame_00078.jpg)

### Rigid Body Animation

![](assets/2019_613_page-065.png)

![](assets/2019_613_page-066.png)

![](assets/2019_613_page-067.png)

The slides show a character with rigidly moving limbs. The text reads "Most geometry only moves rigidly or not at all."

> "So next, let's talk about Rigid Body Animation. So as the name implies, this is animation where objects can move, rotate, and scale, but otherwise completely maintain their shape. So, in the example on the right, even though it looks like the robot is deforming, actually all of its joins are moving rigidly."

![](assets/2019_613_page-068.png)

"May have multiple copies of the same objects."

> "So, in a typical scene, most of the geometry is probably only moving rigidly. In fact, most of the geometry is probably not moving at all. We may also have multiple copies of the same objects in the scene."

### Two-Level Acceleration Structures

![](assets/2019_613_page-069.png)

Three unique objects are shown: A, B, C.

![](assets/2019_613_page-070.png)

Five instances of those three objects: A, A, B, B, C.

![](assets/2019_613_page-071.png)

The instances are placed into a scene. The slide shows five labelled objects ("Object A", "Object B", "Object A", "Object C", "Object B") in a spatial layout.

> "It would be wasteful to replicate these objects multiple times in the accelerations structure and it would also be inefficient to refit or rebuild the entire acceleration structure just because a subset of the geometry is moving. So, to solve both of these problems, we can use what we call a Two-Level Acceleration Structure. So, what we'll do is first build a high-quality triangle acceleration structure for each unique object in the scene."

![](assets/2019_613_page-072.png)

A row of transformation matrices is added above the instances: five `float4x4` values.

![](assets/2019_613_page-073.png)

A row of acceleration structure indices is added: 0, 1, 0, 2, 1. Below, the referenced objects A, B, C are shown in a palette.

![](assets/2019_613_page-074.png)

Both matrices and indices are presented together, showing how each instance selects its source acceleration structure.

> "And we can do this just once when the app starts up. We'll then create two copies of those triangle acceleration structures using a second acceleration structure. Each copy is called an instance of one of the original triangle acceleration structures. Each instance is associated with a transformation matrix, describing where to place it in the scene. So, we'll do this all using two buffers and each buffer will contain one entry for each instance in the scene. The first buffer will contain the transformation matrices for all the instances. The second buffer will contain indices into an array of triangle accelerations structures describing which acceleration structure to use for each instance. We'll then build a second acceleration structure over just the instances in the scene. We can then quickly rebuild just the instance acceleration structure as the objects move."

### Two-Level Acceleration Structure Code

![](assets/2019_613_page-075.png)

![](assets/2019_613_page-076.png)

![](assets/2019_613_page-077.png)

![](assets/2019_613_page-078.png)

Build triangle acceleration structures. The code slide appears progressively across these four pages:

```swift
let group = MPSAccelerationStructureGroup(device: device)
var accelerationStructures : [MPSTriangleAccelerationStructure] = []


// for each unique object:
   let triangleAccelerationStructure = MPSTriangleAccelerationStructure(group: group)
   // configure properties...
   triangleAccelerationStructure.rebuild()


   accelerationStructures.append(triangleAccelerationStructure)
```

> "First, we'll create what's called an AccelerationStructureGroup. All the acceleration structures in the instance's hierarchy must belong to the same group. And this allows them to share resources internally. Next, we'll create an array to hold our triangle acceleration structures. Then finally, we'll loop over all the unique objects in the scene, building a triangle acceleration structure for each of them. Adding them to the array as we go."

![](assets/2019_613_page-079.png)

![](assets/2019_613_page-080.png)

![](assets/2019_613_page-081.png)

![](assets/2019_613_page-082.png)

![](assets/2019_613_page-083.png)

Create the instance acceleration structure:

```swift
let instanceAccelerationStructure = MPSInstanceAccelerationStructure(group: group)


instanceAccelerationStructure.accelerationStructures = accelerationStructures
instanceAccelerationStructure.transformBuffer = transformBuffer
instanceAccelerationStructure.instanceBuffer = instanceBuffer
instanceAccelerationStructure.instanceCount = instanceCount
```

![](assets/2019_613_page-084.png)

And the rebuild step:

```swift
let instanceAccelerationStructure = MPSInstanceAccelerationStructure(group: group)


instanceAccelerationStructure.accelerationStructures = accelerationStructures
instanceAccelerationStructure.transformBuffer = transformBuffer
instanceAccelerationStructure.instanceBuffer = instanceBuffer
instanceAccelerationStructure.instanceCount = instanceCount



// Rebuild when scene changes:

instanceAccelerationStructure.rebuild()
```

> "We're now ready to create the second level acceleration structure. We do this using the MPSInstance AccelerationStructure class. We'll start by attaching our array of triangle acceleration structures as well as the two buffers I talked about previously. Then finally, we'll specify the num of instances in the scene. Then, whenever the objects move or if an object is added or removed from the scene, we can simply rebuild just the instance acceleration structure. This acceleration structure is typically much smaller than a triangle acceleration structure, so we can afford to do this every frame. But note that similar to Refitting, there is some overhead when using instancing. So, if your scene only has one object or a handful of objects, or especially if none of the objects are moving, it might be worthwhile to pack those into a single triangle acceleration structure. This will increase your memory footprint, but it should gain back some of the performance. So, you need to experiment to find the right tradeoff for your application."

![](assets/frame_00084.jpg)

![](assets/frame_00090.jpg)

---

## Denoising

![](assets/2019_613_page-085.png)

Title slide.

![](assets/2019_613_page-086.png)

![](assets/2019_613_page-087.png)

![](assets/2019_613_page-088.png)

Over these slides Sean shows the same Cornell Box first clean, then noisy with only a handful of samples per pixel.

> "So far, all the images that we have seen have been free of noise. That's because they've all been using a denoising filter. If we turn it off, we could see what it would have looked like without the denoiser. We can see that these images are too noisy to use in a real application. That's because we're only using a handful of samples per pixel."

![](assets/2019_613_page-089.png)

The simplest possible denoising diagram: "Noisy Image -> Denoiser -> Clean Image."

> "Usually we would just solve this by averaging together more samples over time. But if the camera or objects are moving it's not quite that simple. Fortunately, Metal now includes a sophisticated Denoising filter. Let's see how this works. Ideally what we'd be able to do is simply take the noisy image output by a renderer, run it through a denoiser and get back a clean image."

### Denoiser Inputs

![](assets/2019_613_page-090.png)

Additional input: Normals and Depth.

> "In practice, the denoiser needs a little more information about the scene. We'll start by providing the depths and normal for the directly visible geometry. Many renderers have these textures lying around, and if not, it's easy to produce them."

![](assets/2019_613_page-091.png)

The Normals/Depth textures are fed into the Denoiser alongside the noisy image.

> "The denoiser will then run a bunch of image processing operations and output a cleaner image. But since we started with just a handful of samples per pixel, the result will still have some noise."

![](assets/2019_613_page-092.png)

A "Previous Frame" input is added.

> "So, we'll revisit the idea of combining samples over multiple frames. So, we'll first set aside the clean image to reuse in the next frame. We'll also set aside the depth and normal so we can compare them to the next frame."

![](assets/2019_613_page-093.png)

The previous frame comes with its own Normals and Depth inputs.

![](assets/2019_613_page-094.png)

"Motion Vectors" are added.

> "Then finally, we'll provide a motion vector texture which describes how much each pixel has moved between frames."

![](assets/2019_613_page-095.png)

![](assets/2019_613_page-096.png)

The full picture with all inputs feeding the denoiser.

> "In the next frame, the denoiser will churn through all of these textures to produce an even better image. And this image will continue to get better over time even if the camera or objects move. The denoiser will use the depths and normal to detect cases where the history for a pixel has become invalid due to an object moving or getting in the way."

![](assets/frame_00096.jpg)

### MPSSVGF

![](assets/2019_613_page-097.png)

Sean introduces the API.

> "So, this is all implemented using the MPSSVGF family of classes. This is an implementation of the popular Spatiotemporal Variance-Guided Filtering denoising algorithm. This algorithm makes a good tradeoff between high quality and real-time performance."

![](assets/2019_613_page-098.png)

"MPSSVGFDenoiser" is called out.

> "So, the denoising process is all coordinated by the MPSSVGFDenoiser class."

![](assets/2019_613_page-099.png)

"MPSSVGF" itself is called out as the low-level control layer.

> "Meanwhile, low-level control is provided using the MPSSVGF class. This class provides the individual compute kernels used by the denoiser and exposes many parameters you can use to fine tune the Denoising in your application. And you also just call this classes' methods directly to build a customized denoiser."

![](assets/2019_613_page-100.png)

"Low-level control" text appears.

![](assets/2019_613_page-101.png)

"MPSSVGFTextureAllocator" protocol is added.

> "Now the denoiser creates and destroys quite a few temporary textures throughout the Denoising process. The MPSSVGF texture allocator protocol serves as a cache for these memory allocations. You can either use the default implementation or implement this protocol yourself to share memory with your own application. So as usual, we've optimized these classes for all of our Mac and iOS devices. The denoiser can process two independent images simultaneously. For example, you might want to split your direct and indirect lighting terms into separate textures. There's also a fast path for single channel textures such as Ambient Occlusion or shadow textures, which is faster than Denoising a full RGB image."

### MPSSVGFDenoiser Setup

![](assets/2019_613_page-102.png)

![](assets/2019_613_page-103.png)

![](assets/2019_613_page-104.png)

![](assets/2019_613_page-105.png)

The setup code is built up across these four slides:

```swift
// Allocate the denoising kernels
let svgf = MPSSVGF(device: device)


// Configure SVGF properties


// Create a custom texture allocator or use the default allocator
let textureAllocator = MPSSVGFDefaultTextureAllocator(device: device)


// Create the denoiser object
let denoiser = MPSSVGFDenoiser(SVGF: svgf, textureAllocator: textureAllocator)
```

> "So first we'll create the MPSSVGF object and configure its properties. All we need to provide is the Metal device we want to use for Denoising. Next, we'll create the TextureAllocator. In this case we'll just use the default implementation. Then finally, we'll create the high level Denoiser object which will manage the denoising process."

### MPSSVGFDenoiser Encoding

![](assets/2019_613_page-106.png)

![](assets/2019_613_page-107.png)

![](assets/2019_613_page-108.png)

![](assets/2019_613_page-109.png)

Encode into a command buffer:

```swift
denoiser.sourceTexture = textureToDenoise
denoiser.depthNormalTexture = depthNormalTexture
denoiser.previousDepthNormalTexture = previousDepthNormalTexture
denoiser.motionVectorTexture = motionVectorTexture


denoiser.encode(commandBuffer: commandBuffer)


let denoisedTexture = denoiser.destinationTexture
```

> "So now we're ready to do some denoising. We'll start by attaching all of the input textures to the Denoiser. Now we simply encode the entire denoising process to a Metal commandBuffer. And finally, we can retrieve the clean image from the denoiser. And that's all you need to do to enable denoising your applications."

![](assets/frame_00102.jpg)

### Recap of Building Blocks

![](assets/2019_613_page-110.png)

Sean recaps. The slide lists:

- Ray/triangle intersection
- Dynamic scenes
- Denoising

> "So, we now talked about all of the basic building blocks available in Metal for Ray Tracing and Denoising. We reviewed how to do basic ray/triangle intersection using the MPS Ray Intersector API. We then talked about how to extend this to dynamic scenes using Refitting and Two-Level Acceleration Structures. And finally, we talked about how to remove the noise from your images using the MPSSVGF classes. Now, don't worry if this is all a little bit overwhelming. We've written a sample, which demonstrates how to use all of these concepts which is available online. Now, I mentioned earlier that we need to be careful with performance. Especially in a real-time setting. So next, I'd like to bring out my colleague Wayne who will talk about how to make all of this work on real devices with real performance budgets."

![](assets/frame_00108.jpg)

---

## Ray Tracing in Practice

![](assets/2019_613_page-111.png)

Wayne takes the stage.

> "Hi everyone. Now, what I'd like to show you in this part of the talk is how to use the Ray Tracing features that we have in Metal to implement a few different rendering techniques in your applications. So, in particular, I'll be focusing on hard and soft shadows, Ambient Occlusion, and global illumination."

![](assets/frame_00114.jpg)

---

## Hard Shadows

![](assets/2019_613_page-112.png)

The title slide.

![](assets/2019_613_page-113.png)

A rendered scene with sharp, precise ray-traced shadows under an industrial building.

> "So, let's start with hard shadows. Now, the way that we model this with Ray Tracing is to take points on our surface and fire rays up in the direction of the sun. If a ray hits something, then the associated point is in shadow. Otherwise, it's in sunlight."

### Hybrid Rendering

![](assets/2019_613_page-114.png)

Title card: "Hybrid Rendering."

![](assets/2019_613_page-115.png)

The diagram starts with the existing rasterization path: G-Buffer -> Shading -> Shaded Image.

> "Now, to incorporate this into an existing application, I'm going to assume that you're starting with something a bit like this. You've rasterized a G-Buffer and run a compute pass for your lighting. And the output of that is your final shaded image."

![](assets/2019_613_page-116.png)

A new branch is added: "Ray Generation" -> Ray Buffer.

> "Now, to take advantage of Ray Tracing here we'll start by taking the G-Buffer and then run a compute shader to generate some rays."

![](assets/2019_613_page-117.png)

The Intersector is added, producing an Intersection Buffer.

> "We'll then pass those rays to Metal to intersect with an acceleration structure. And Metal will output the results to an intersection buffer."

![](assets/2019_613_page-118.png)

![](assets/2019_613_page-119.png)

The intersection buffer feeds into Shading.

> "You can now use this buffer in your shading kernel to decide whether your surface points are in shadow. Now the main part I'd like us to focus on here is Ray Generation."

![](assets/frame_00120.jpg)

### Ray Generation Code

![](assets/2019_613_page-120.png)

A short snippet of Metal Shading Language showing shadow ray setup:

```metal
MPSRayOriginDirection ray;


ray.origin = worldPosition + worldNormal * SURFACE_BIAS;
ray.direction = directionToLight;


rayBuffer[outputIndex] = ray;
```

> "So, let's start with a quick reminder of how rays are described in Metal. So, Metal provides a few different ray structures for you to use, and at a minimum these contain fields for your ray origin and your ray direction. So just fill out one of these structures for each ray that you want to trace and write it out to your ray buffer."

### Ray Coherency

![](assets/2019_613_page-121.png)

The slide shows rays laid out in row-linear order. A pixel grid is coloured with a numbering that scans left-to-right, top-to-bottom.

> "Now, the way in which you arrange your rays in your ray buffer, that has a performance impact."

![](assets/2019_613_page-122.png)

The row-linear label is reinforced.

> "So, often you might start like this. We call this row linear order. Now, the problem here is that as Metal works its way through these rays, they tend to hit very different nodes in the internal data structures that Metal uses to accelerate ray traversal. Now this in turn can flash the underlying hardware caches."

![](assets/2019_613_page-123.png)

A second layout appears alongside the first: Block Linear, with 4x4 blocks coloured.

> "So, a better approach is to use block linear ordering. So, rays from nearby pixels on the screen, they tend to hit the same parts of your acceleration structure, and so by storing your rays like this it enables Metal to drive the hardware much more efficiently. Now, in the visualization here, I'm showing you a block size of 4 by 4. In practice we found that 8 by 8 works really, really well."

![](assets/frame_00126.jpg)

### Disabling Rays

![](assets/2019_613_page-124.png)

The slide lists reasons to skip shadow rays:

- Background pixels
- Surfaces facing away from the Sun

And the trick: set `maxDistance < 0.0`.

> "So, optimizing your ray storage is a great way to improve performance. But where possible, an even better way is just not to fire rays at all. Now, in the context of shadows, the reason that you might want to do this is because not all pixels need a shadow ray. For example, pixels on your background, on your skybox, or on surfaces that are facing away from the sun. Now, it's likely that your ray buffer contains a ray structure for each pixel on the screen. So, what we need here is a way to tell Metal to skip firing ways for the pixels that we just don't care about. Now, there's a few ways to do this. The approach I'm showing you here is simply to set the maxDistance field in your ray structure to a negative value. And that's the main things you need to know for Hard Shadows."

### Hard Shadow Result

![](assets/2019_613_page-125.png)

A rendered output image showing hard shadows with very sharp, precise edges.

> "As you can see, Ray Tracing gives really great results. The shadows are very crisp and they're very precise."

![](assets/frame_00132.jpg)

---

## Soft Shadows

![](assets/2019_613_page-126.png)

Title slide.

![](assets/2019_613_page-127.png)

A reference photo of a real world scene. The shadow from the lamp post starts hard at its base and softens with distance.

> "But in reality, shadows cast by the sun, they tend not to look that sharp. They look more like this. They're soft around the edges and that softness varies with distance. And you can see a great example of this on the left there. The shadow from the lamp post starts off hard at the base and it softens as the distance to the ground increases."

![](assets/2019_613_page-128.png)

A diagram showing a cone extended from the surface point up to the sun.

> "So, to model that with Ray Tracing, instead of using the parallel rays that I was showing you earlier, we'll instead extend the cone from our surface point all the way up to the sun."

![](assets/2019_613_page-129.png)

The cone filled with randomly distributed rays. Some intersect occluders, some do not.

> "And then, we'll generate some ray directions randomly within this cone. Now you can see there that some rays intersect geometry and some don't. And it's this ratio that controls the softness of your shadow."

![](assets/2019_613_page-130.png)

Same diagram with the intersection count annotated.

### Shadow Term and Denoising

![](assets/2019_613_page-131.png)

Raw direct lighting output, one ray per pixel. It is grainy and noisy.

> "So, here's what that looks like. What I'm showing you here is the raw direct lighting term ray traced with one ray per pixel. So, in this image, all other effects such as reflections and global illumination, they're all disabled so we can focus purely on the shadow. And as you can see, the result is really quite noisy. Now, to deal with that, we could just keep firing more and more rays. But since that's something we're really trying to avoid in a real time application, what we can do instead is use the Denoiser that Sean was telling us about earlier."

![](assets/2019_613_page-132.png)

The same frame after SVGF denoising, now showing smooth, photorealistic soft shadows.

> "And here's the results of that. Most of the noise is filtered away and we get these great looking soft shadows with just one ray per pixel. And I'll be showing you this in action in our live demo later on."

![](assets/frame_00138.jpg)

---

## Ambient Occlusion

![](assets/2019_613_page-133.png)

Title slide.

![](assets/2019_613_page-134.png)

A surface point in the centre, with a blue block to the right playing the occluder role.

> "So essentially, this is an approximation of how much ambient light is able to reach the surface. And as you saw in our AR Quick Look demo earlier, it's a really great technique for grounding objects in their environments. So, let's visualize how this works with Ray Tracing. We have a surface point in the middle of the screen there and there's a blue block over on the right that's going to play the role of our occluder."

![](assets/2019_613_page-135.png)

An imaginary hemisphere is drawn around the surface point.

> "We define an imaginary hemisphere around our surface points and then we fire some rays. If a ray hits something, and we found that object is blocking ambient light from reaching the surface."

![](assets/2019_613_page-136.png)

![](assets/2019_613_page-137.png)

Annotations: "Use rays to estimate how much ambient light reaches a surface" and "Falloff based on angle and intersection distance."

### Importance Sampling

![](assets/2019_613_page-138.png)

The motivation: "Use importance sampling to generate rays. Fewer rays for same visual quality."

> "Now, as I've mentioned a couple of times now, in a real time application, we're really trying to limit ourselves to just one or two rays per pixel. So, we need to use these rays as efficiently as we can. Now, one of the ways to do this is importance sampling. And the general idea here is to fire rays in the directions where we expect they'll contribute most to our final image."

![](assets/2019_613_page-139.png)

Hemisphere sampling: rays distributed uniformly in a hemisphere around the normal.

> "Now with Ambient Occlusion the most important rays are the ones closer to the normal. So instead of firing rays evenly in a hemisphere like you see here..."

![](assets/2019_613_page-140.png)

![](assets/2019_613_page-141.png)

![](assets/2019_613_page-142.png)

Cosine sampling: rays concentrated near the surface normal, fewer near the horizon.

> "...we instead use cosine sampling. Now, this distributes fewer rays around the horizons and more rays around the surface normal. And that's great. That's exactly where we need them."

![](assets/2019_613_page-143.png)

"Distance sampling" is added.

> "Now in addition to this angular falloff, Ambient Occlusion also has a distance term. So, objects close to the surface, they tend to block the most light. And there's usually a fall off function in there too, proportional to the square of distance."

![](assets/2019_613_page-144.png)

A visualization of rays of varying length, the majority short.

> "Now, interesting thing we can do here is bake that fall off function right into the ray distribution itself. And the way we do this is by firing rays of different lengths. So, as you can see here, because of that distance squared fall off function I was telling you about, the majority of rays end up being quite short. Now this is great for performance. Short rays are much easier for Metal to trace through the acceleration structures."

![](assets/frame_00144.jpg)

### Parameter Space and Low Discrepancy Sequences

![](assets/2019_613_page-145.png)

"Points in 2D parameter space map to 3D ray distributions."

> "So, a couple of times now, I've talked about generating rays in various shapes and various distributions, such as the cones we were using for Soft Shadows and the hemisphere's that we're using for Ambient Occlusion. Now, the way that this works in practice is we begin by generating points in 2D parameter space and then we map that space with whichever ray distribution you want to use."

![](assets/2019_613_page-146.png)

![](assets/2019_613_page-147.png)

![](assets/2019_613_page-148.png)

A Random sample plot is shown. Points clump together and leave voids.

> "Now the position of these points in parameter space can have a big effect on image quality. If you choose them randomly, you tend to end up with regions where sample points clump together. Now this causes us to fire rays in pretty much the same direction and that's just wasting rays. You can also get areas without any sample points at all. Now this impacts image quality because we're undersampling the scene in these areas."

![](assets/2019_613_page-149.png)

A Halton (2, 3) sample plot is shown alongside Random. The Halton distribution is clearly much more even.

> "So, a better approach to generate sample points is to use something called a low discrepancy sequence. So, the one I'm showing you up on the screen here is the Halton 2,3 sequence. You can see that sample points generated in this way, they cover the space far more evenly and we vanish the void by plumping and undersampling."

### Pixel Decorrelation

![](assets/2019_613_page-150.png)

![](assets/2019_613_page-151.png)

![](assets/2019_613_page-152.png)

The slides build up the concept: "Neighboring pixels sample different directions. Can use same low discrepancy sample for all pixels."

> "So that's how to generate good rays for a single pixel. And what we need to do now is scale that to generate good rays for all pixels on the screen. Now, the way that we're doing this is by taking one of those low discrepancy sample points I was just showing you and then we apply a random delta for each pixel. Now, the effect of that is that each pixel still runs through a low discrepancy sequence, but the exact positions of the sample points are offset from neighboring pixels on the screen."

![](assets/2019_613_page-153.png)

"White Noise" is labelled on a noise texture. The texture appears grainy and uneven.

> "Now, there's a couple of different ways to generate these deltas. One way is just to sample an RG texture full of random numbers. What we saw previously that random numbers aren't always a great choice for Ray Tracing."

![](assets/2019_613_page-154.png)

"Blue Noise" is added. The blue noise texture visibly has more even distribution.

> "And an alternative that works really well for Ambient Occlusion is blue noise. So, you can see on the right there that the randomness is the blue noise texture, it's distributed far more evenly and that's great for image quality. Particularly when we're limited to just a couple of rays per pixel."

### Ray Traced Result

![](assets/2019_613_page-155.png)

A rendered frame using hemisphere sampling and random deltas.

> "So, let's look at the effect of all of this on the Ambient Occlusion result that we were trying to generate. So, here's what we started with. This is using hemisphere sampling and random deltas for all pixels."

![](assets/2019_613_page-156.png)

The same frame rendered with cosine sampling and blue noise. The detail is visibly sharper and the noise much reduced.

> "And this is what we get with cosine sampling and the blue noise that I was telling you about. So, I'll flip between these images so you can see. Now, both of these images are generated using just two rays per pixel. But you can see by being selective about how we use those rays, the amount of noise is significantly reduced. And we've managed to capture much more of the fine surface detail. And if we were to keep firing rays, eventually the two approaches would converge on exactly the same image. But using importance sampling gets us there much faster."

![](assets/frame_00150.jpg)

### Handoff

![](assets/2019_613_page-157.png)

The slide spells out "PLACEHOLDER" in vertical letters as a transition.

> "So that's Shadows and Ambient Occlusion. And for these effects we were really only interested in whether our rays hit something or whether they missed. Now, for many of the other effects that we typically associate with Ray Tracing, such as Global Illumination, you need to model your rays as they bounce around the scene. And to talk some more about that I'll invite up my colleague Matt."

---

## Global Illumination

![](assets/2019_613_page-158.png)

Matt takes the stage.

> "Thanks Wayne. So, we're going to cover a few topics in this section, starting with a brief overview of Global Illumination."

![](assets/2019_613_page-159.png)

Section outline:

- What is Global Illumination?
- Memory
- Ray Lifetime
- Debugging

![](assets/2019_613_page-160.png)

The first bullet is highlighted.

> "Then, we'll go into some best practices for memory and ray management. Finally, we'll cover some strategies for debugging your Ray Tracing application."

![](assets/frame_00156.jpg)

### What Is Global Illumination?

![](assets/2019_613_page-161.png)

A four-panel illustration showing light bouncing. Panel 1: direct light hitting a Cornell Box. Panel 2: first indirect bounce. Panel 3: second bounce. Panel 4: final result with full GI.

> "So, what is Global Illumination? Conceptually it's pretty simple. Light enters the scene and directly illuminates the surfaces that it hits. And rasterization, that's typically the end of the rendering process."

![](assets/2019_613_page-162.png)

![](assets/2019_613_page-163.png)

![](assets/2019_613_page-164.png)

The panels progressively light up showing:

- Direct lighting only (panel 1)
- First bounce adds specular reflections and softer shadows (panel 2)
- Second bounce adds reflections within reflections and refracted light through glass (panel 3)
- Full result (panel 4)

> "But in the real world, those objects absorb some of the light and then the rays bounce off and keep traveling around the scene. And as they bounce around, some interesting visual effects emerge. After light has bounced once we start to see specular reflections on the mirrored surfaces like the ball and wall to the right. You can also see that objects and shadows get brighter as they pick up light that's been reflected off nearby surfaces. After the light has bounced twice, we start to see reflections between mirrored surfaces and eventually, some rays have refracted all the way through transparent objects, and they're showing the surfaces behind them giving us the glass effect of the box."

![](assets/frame_00162.jpg)

### Working Backwards from the Camera

![](assets/2019_613_page-165.png)

![](assets/2019_613_page-166.png)

![](assets/2019_613_page-167.png)

![](assets/2019_613_page-168.png)

Matt explains why a path tracer works backwards.

> "Now, if we tried to model all the light bouncing around the scene only a small portion of it would actually make it back to the camera and that would be pretty inefficient. So instead, we'll work backwards from the camera towards the light source. We cast rays from the camera towards the pixels in our image. The intersection points of those rays tell us what objects are visible. But we'll need to figure out how much light is reaching them in order to figure out what their color in the final image should be."

![](assets/2019_613_page-169.png)

![](assets/2019_613_page-170.png)

Shadow rays are cast from the hit points back to the lights.

> "Earlier, Wayne described how to calculate soft shadows and here we're going to be performing exactly the same process. We cast shadow rays from the intersection points towards the lights in the scene in order to approximate how much light's reaching them. That's used as the light contribution towards the final image."

![](assets/2019_613_page-171.png)

![](assets/2019_613_page-172.png)

Secondary rays are cast from the hit points in random directions.

> "Next, from the intersection points we cast secondary rays in random directions. We use Metal to figure out what those rays hit and then cast shadow rays to determine their direct lighting and then use that to add light to the final image. By repeating this process, we can simulate light bouncing around the room. We described this extensively in last year's talk, so I'll refer you to that for more details on how to go through this process."

![](assets/frame_00168.jpg)

### Global Illumination Pipeline

![](assets/2019_613_page-173.png)

The familiar pipeline: Generate Rays -> Intersector -> Process Results.

> "Our pipeline for this will look a little bit different than the hybrid pipelines that we've seen so far. First, we set up rays and use Metal to find their intersections with the scene. Then, we write a shader to process the results of those intersection tests to tell us what surfaces we hit."

![](assets/2019_613_page-174.png)

A second row is added: Generate Shadow Rays -> Intersector -> Add Light to Final Image.

> "Then, we generate shadow rays from those intersection locations towards the lights in the scene. I'll write a shader to figure out which of those rays hit the light and then add their light to the final image."

![](assets/2019_613_page-175.png)

The feedback loop is drawn: the Final Image feeds back into another Generate Rays step.

> "Finally, we use the hit surfaces as the starting positions for our next set of rays. We repeat this process over and over again until we've modeled as many ray bounces as we like. So that's how Global Illumination works."

### Section Navigation

![](assets/2019_613_page-176.png)

![](assets/2019_613_page-177.png)

The outline is revisited, moving to Memory.

> "Now we'll discuss some best practices that come up with memory for this programing model."

![](assets/frame_00174.jpg)

---

## Memory

### Data Requirements

![](assets/2019_613_page-178.png)

The slide lists the per-ray state we must carry between iterations:

- Ray Position
- Ray Direction
- Ray Type
- Index of Refraction
- Hit Surface Properties
- Ray Color
- ...

> "As any ray bounces around the scene. Its state changes depending on its interactions with the objects that it hits. For instance, if a ray hits a red material that surface absorbs everything but the red component of the light. So, the secondary rays that reflect off of that surface will only carry red light. So, we'll have to keep track of that information in order to pass it to the next iteration of our pipeline. That means we'll have to allocate a bunch of resources to keep track of ray and scene properties."

### Memory Usage

![](assets/2019_613_page-179.png)

The slide describes the scale of the problem:

- The ray buffer alone for a 4K image is 250MB
- Our demo uses 80B per ray
- Can quickly exceed available GPU memory

> "With all these new buffers relocated we're going to be using a lot of memory. For a 4K image, the ray buffer alone would be 250 MB. In one of our demos, we're using almost 80 bytes per ray. And this approach can quickly exceed the amount of available GPU memory."

![](assets/2019_613_page-180.png)

Solution: batch into tiles. Limit simultaneous rays.

> "One solution to this is just to batch up your rays into smaller groups or tiles. And by restricting the number of rays that you're launching simultaneously you can drastically reduce the memory footprint of your resources."

### Bandwidth Overload

![](assets/2019_613_page-181.png)

The slide: "Paging data in and out is a major limiting factor. For a 4K image 8,294,400 rays per pass. 5GB of data per iteration at 80B per ray! May use more with supersampling."

> "Because the data in these buffers is going to be passed between pipeline iterations, storing that data out and then reading it in, in the next pass is going to be a major limiting factor. For 4K image we're using over 8 million rays. And for that number of rays, we're reading and writing almost 5 gigabytes of data per pass."

![](assets/frame_00180.jpg)

### Reducing Bandwidth Usage

![](assets/2019_613_page-182.png)

Top-level checklist:

- Coalesce loads and stores
- Use smaller data types where possible
- Split structs

> "There's no one solution to every bandwidth problem, but we can give you some best practices that worked well for us. First, don't index into your data buffers randomly. It's much more efficient if you can index by thread ID, so the compiler can coalesce all of the loads and stores since the memory the threads are accessing will be in adjacent buffer positions. This is really going to improve your cache coherency. Next, for variables where you don't need full precision, consider using smaller data types where possible. Try to use half instead of float data types for ray and scene and material properties if you can. Finally, split up structs if possible, to avoid loading or storing data you're not going to use."

![](assets/2019_613_page-183.png)

Counterintuitive advice: use your own origin and direction buffers instead of the full Metal ray struct.

```metal
struct MPSRayOriginMinDistanceDirectionMaxDistance {
     packed_float3 origin;
     float minDistance;
     packed_float3 direction;
     float maxDistance;
};


packed_half3 *origin;
packed_half3 *direction;
```

> "It might be counter intuitive, but it may be more efficient to allocate your own buffers to store origin and direction data rather than reusing the Metal ray buffer structs. This is because the Metal ray buffers may contain extra data numbers that you don't want to have to load and store for every shader that may access the ray."

### Occupancy

![](assets/2019_613_page-184.png)

Reduce register pressure:

- Track simultaneously live variables
- Don't hold onto structs
- Be careful with loop counters, function calls

> "To maximize your GPU usage, you need to be mindful of your shader occupancy. Occupancy is a huge topic, so we won't go into it in depth here. But if you are getting occupancy problems the easiest way to improve it is to reduce your register pressure. So, be conscious of the number of simultaneously live variables that you have in your shader. Be careful with loop counters, function calls, and don't hold on to full structs if you can avoid it."

### Textures

![](assets/2019_613_page-185.png)

- Can't predict what surface a ray will intersect
- Sponza scene has 76 textures
- Quickly run out of binding slots

> "When we process ray intersection points we need to evaluate the surface properties of whatever object a ray hits. And graphics applications typically store a lot of the material properties in textures. The problem here is that because a shader may need access to any texture that an object references, and we don't know in advance what object a ray is going to hit, we may potentially need access to every texture that's in the scene. And this can get out of hand quickly. For instance, the commonly used Sponza Atrium scene has 76 textures, which is over double our available number of bind slots. So, we'll pretty quickly run out of binding locations."

### Argument Buffers

![](assets/2019_613_page-186.png)

![](assets/2019_613_page-187.png)

![](assets/2019_613_page-188.png)

![](assets/2019_613_page-189.png)

![](assets/2019_613_page-190.png)

The code block appears across these slides, with a cross-reference to "Introducing Metal 2, WWDC 2017":

```metal
struct Material {
      texture2d<float> texture;
      // ...
};


kernel void shadingKernel(const device Material *materials,
                           const device Intersection *intersections,
                           /* ... */)
{
     unsigned int primitiveIndex = intersections[tid].primitiveIndex;
     const device Material & material = materials[primitiveIndex];
     texture2d<float> texture = material.texture;
}
```

> "One way to address this is by using Metal Argument Buffers. A Metal Argument Buffer represents a group of resources that can be collectively assigned as a single argument to a shader. We gave a talk on this at WWDC two years ago. So, I'll refer you to that for more details on how to use them. Assuming we have one texture per primitive, our argument buffer will be a struct that contains a reference to a texture. Here, we've set up a struct that we called material that contains a texture reference and any other information we'd like to access. Next, we bind our argument buffer to a compute kernel. It will appear as an array of material structs. We read from our intersection buffer to find out what primitive the ray hit and then we index into our argument buffer using that index. That lets us access a unique texture for every primitive."

![](assets/frame_00186.jpg)

---

## Ray Lifetime

![](assets/2019_613_page-191.png)

![](assets/2019_613_page-192.png)

The section outline re-appears, now with the Ray Lifetime bullet highlighted.

> "That covers our memory topics. Now we'll discuss managing the lifetime of your rays."

### Eliminating Inactive Rays

![](assets/2019_613_page-193.png)

Rays can stop contributing:

- Leave the scene
- Ray no longer carries enough light to make a measurable impact
- Total internal reflection for transparent surfaces

> "As your ray bounces around the scene it can stop contributing to the final image for a variety of reasons. First, it may leave the scene entirely. Unlike the real world, your scene takes up a finite amount of space, and if the ray exits it there's no way for it to make its way back in. If that happens, we typically evaluate an environment map to get a background color, but that ray is effectively dead. Second, as the ray bounces, the light it carries will be attenuated by the surfaces is interacts with. If it loses enough light it may not be able to have a measurable impact on the final image. And finally, with transparent surfaces, there are some rays that can get trapped in position, such that they can never get back to the camera."

### Inactive Rays Across Iterations

![](assets/2019_613_page-194.png)

A chess set with an environment map, the example scene. Ray buffer visualization: 8 rays, all active, "First iteration: 100% of rays active."

> "So how quickly to rays become inactive? Well, depending on the kind of scene it can be quite rapid. For example, this scene has an open world and a lot of the rays will exit quickly by hitting the environment map. On the right, we're showing a simplified representation of a fully active ray buffer as it would exist for the first iteration of our pipeline. This is the step where we cast rays from the camera towards the scene."

![](assets/2019_613_page-195.png)

Second iteration. Rays 1, 3, 6 have gone inactive (shown yellow). 57% of rays remain active.

> "Some of those rays will hit the environment map and become inactive. Here, we've colored inactive rays yellow and we've removed them from the ray buffer. After the first pass only 57 percent of our rays are still active."

![](assets/2019_613_page-196.png)

Third iteration: ray 0 has also left. 43% active.

> "When we let the rays continue traveling, some of the rays that initially hit the ground bounce up and hit the environment map. Now we're down to 43 percent of rays that left active."

![](assets/2019_613_page-197.png)

Fourth iteration: ray 5 drops out. 32% active.

> "Now, some of the rays travel all the way through the transparent objects and eventually exit the scene. We've only got about a third remaining active."

![](assets/2019_613_page-198.png)

Fifth iteration: 23% active.

> "And of course, the more we iterate, the more rays become inactive."

![](assets/frame_00192.jpg)

### Sparsely Utilized Threadgroups

![](assets/2019_613_page-199.png)

- Threadgroups become sparsely utilized
- Ray intersector must still process inactive rays
- Control flow statements to cull inactive rays

> "In this example we know a lot of the rays in our ray buffer will be inactive, and anytime we spend processing them will be wasted. But because we don't know in advance which rays are going to be inactive, the Metal Ray Intersector and all of the shaders that process its results are still going to have to be run on all of them. That means we'll have to allocate thread group memory, the compiler may be prefetching data, and we may have to add control flow statements to cull inactive rays. Our occupancy here stays the same, but our thread groups have become sparsely utilized. And we're wasting all that processor capacity."

### Ray Compaction

![](assets/2019_613_page-200.png)

- Only add active rays to the next ray buffer
- Threadgroups are fully utilized
- Also works for shadow rays

The slide illustrates compaction: a sparse buffer `_ _ 2 _ 4 _ _ 7` becomes `7 2 4`.

> "Our solution to this is to the compact the ray buffers. For every pass we only add active rays to the next passes ray buffer. This adds some overhead, but it results in the cache lines and thread groups being fully utilized so there's less waste of processing and less bandwidth required. It's also important to note that this can be used for shadow rays as well. Some rays will hit surfaces that are pointing away from a light or they may hit the background. So, we won't want to cache shadow rays for them."

![](assets/2019_613_page-201.png)

Same visualization in another framing.

![](assets/2019_613_page-202.png)

The slide adds: "Buffer indices no longer map to constant pixel locations. Need to track pixel coordinates for each ray."

Two example buffers are shown: rays with pixel indices `24, 75, 403, 302, 18, 99` stored at the respective positions in the outgoing buffer.

> "The downside is that because we're shuffling ray positions within the ray buffers, the indices in our ray buffer no longer map to constant pixel locations. So, we'll need to allocate a buffer to start tracking pixel coordinates along with each ray. Even though we're using extra buffers, we'll actually be using much less memory if we factor in all of the rays that we don't have to process."

### Ray Compaction Code

![](assets/2019_613_page-203.png)

![](assets/2019_613_page-204.png)

![](assets/2019_613_page-205.png)

The atomic-based compaction kernel:

```metal
kernel void compactionKernel(device atomic_uint & outgoingRayCount,
                            device Ray & outgoingRays,
                            /* ... */)
{
    unsigned int outgoingRayIndex =
       atomic_fetch_add_explicit(&outgoingRayCount, 1, memory_order_relaxed);


    // Setup ray


    outgoingRays[outgoingRayIndex] = ray;
}
```

> "When we're compacting the rays, we don't want two shaders to try to add rays to the new ray buffer at the same location. Therefore, we need to produce a unique index into the ray buffer for every ray that remains active between passes. We use an atomic counter to do this. Here, the atomic integer outgoingRayCount contains the current number of rays in the new ray buffer. We use atomic fetch add explicit to grab the current value of outgoing ray count and increment it by one. Using that value as the index into the outgoing ray buffer ensures that we don't get conflicts. It has the added benefit of leaving the number of rays that remain active in outgoing ray count."

### Indirect Dispatch

![](assets/2019_613_page-206.png)

![](assets/2019_613_page-207.png)

![](assets/2019_613_page-208.png)

Launch one thread per ray using indirect dispatch:

```swift
// Fill out MTLDispatchThreadgroupsIndirectArguments in indirectBuffer in a compute kernel


computeEncoder.dispatchThreadgroups(indirectBuffer: indirectBuffer,
                                   indirectBufferOffset: indirectBufferOffset,
                                   threadsPerThreadgroup: threadsPerThreadgroup)
```

> "Now, Ray Compaction doesn't help you much if you can't restrict the number of threads that you're launching. The outgoing ray count buffer we just produced contains the total number of active rays in our outgoing ray buffer. We can use that to fill out an MTLDispatch ThreadGroups IndirectArguments object. That just specifies launch dimensions to be used with the dispatch. Then, by using IndirectDispatch with that indirectBuffer object we can restrict the number of threads that we're launching to only process the rays that remain active."

### Indirect Ray Intersection

![](assets/2019_613_page-209.png)

![](assets/2019_613_page-210.png)

```swift
intersector.encodeIntersection(commandBuffer: commandBuffer,
                              intersectionType: .nearest,
                              rayBuffer: rayBuffer,
                              rayBufferOffset: rayBufferOffset,
                              intersectionBuffer: intersectionBuffer,
                              intersectionBufferOffset: intersectionBufferOffset,
                              rayCountBuffer: outgoingRayCount,
                              rayCountBufferOffset: outgoingRayCountOffset,
                              accelerationStructure: accelerationStructure)
```

> "There's also a version of the ray intersection function that corresponds to this. The important point here is that we can pass our ray count via a buffer, so we can feed the result of our ray compaction step in as the number of threads to launch. After Ray Compaction we get about a 15 percent performance gain in this scene. But of course, your results will depend on the complexity of the scene you're using and the number of ray bounces."

![](assets/frame_00198.jpg)

---

## Debugging

![](assets/2019_613_page-211.png)

![](assets/2019_613_page-212.png)

![](assets/2019_613_page-213.png)

Section navigation, moving to the Debugging bullet.

> "So that covers ray lifetime and culling. Now we're going to discuss debugging your application with Xcode."

### Debugging Image Corruption

![](assets/2019_613_page-214.png)

- Xcode makes this a breeze to debug
- Frame capture

> "Debugging on the GPU is notoriously difficult process. And this is especially true for Ray Tracing. Any change you make may get invoked multiple times per ray and you might have to write a lot of code to dump out buffers and textures for a bunch of different stages of your algorithm to get a clue about where an error was introduced. Xcode's frame capture tools are amazing for debugging exactly these kinds of issues. It's incredibly powerful and a real time saver."

![](assets/2019_613_page-215.png)

The slide emphasizes the topic.

### Debugging with Xcode: A Walkthrough

![](assets/2019_613_page-216.png)

![](assets/2019_613_page-217.png)

![](assets/2019_613_page-218.png)

![](assets/2019_613_page-219.png)

![](assets/2019_613_page-220.png)

![](assets/2019_613_page-221.png)

![](assets/2019_613_page-222.png)

![](assets/2019_613_page-223.png)

![](assets/2019_613_page-224.png)

![](assets/2019_613_page-225.png)

A series of Xcode screenshots walks through a super-sampling bug. Frame capture, the shader list, and the resource inspector are shown. The first image is just a bit too bright. The second is washed out. The third is almost fully white.

> "So, I'm going to walk you through debugging a real-world issue that we hit when we implemented super sampling in our ray tracer. We implemented the ability to sample a single pixel multiple times per frame and all of a sudden, our ray tracer is producing a blown-out image. The first step is just to do a frame capture as your application is running. This records the state of the GPU for every API call and shader over the course of a frame. By selecting any shader, we can examine the resources that are bound to it so we can really quickly narrow down exactly what shader's failing by just selecting all of the shaders that write to the frame buffer and examining the frame buffer contents directly. So here we can see the first image is pretty light. The second image is pretty washed out. And the third is almost white. But here we're going to select the shader that outputs the lightest image and we're going to take a look at the two input buffers that we used to calculate the frame buffer. And the first buffer just contains the sum of all the light a ray has accumulated. The second buffer contains our new variable. And that's just the number of times we've sampled a given pixel. Both of these buffers look like they have valid data in them, so we'll go directly to the shader debugger to examine what our shader is doing with this data. Our color calculation is just that some of the luminance for all the rays that were launched for a given pixel. When we only had one ray per pixel, this worked just fine. But now, we're failing to compensate for the fact that we're sampling multiple times per pixel. So, we're going to change that code in the shader debugger to divide the total luminance by the number of input samples. We reevaluate directly in the shader debugger and we can instantly see that our output image has been fixed. It's just that easy."

![](assets/frame_00204.jpg)

![](assets/frame_00210.jpg)

### Performance Tuning with Xcode

![](assets/2019_613_page-226.png)

The first struct, tracking surface characteristics in a single block:

```metal
struct Surface {
     float3 baseColor;
     float shininess;
     float roughness;
     float emissive;
     float3 transmission; // transparency
     float indexOfRefraction;
};
```

> "Another issue we hit frequently was trying to understand the performance impact of our changes. Xcode frame captures tools make this easy as well. Here's an example of a struct that tracks surface characteristics across ray bounces. Not every surface in our scene uses transparencies. The final two values, transmission and index of refraction, won't be used for some rays. But, because we've packed all of that data into a single struct, rays that don't hit transparent surfaces are still going to have to pay the penalty for reading and writing those fields out between passes."

![](assets/2019_613_page-227.png)

The refactored version splits the refraction data into its own struct:

```metal
struct Surface {
     float3 baseColor;
     float shininess;
     float roughness;
     float emissive;
};
struct SurfaceRefraction {
     float3 transmission; // transparency
     float indexOfRefraction;
};
```

> "Here, we've refactored the index of refraction variables into their own struct. By separating the structs only rays that hit transparent surfaces will have to touch the refraction data. But we can still do a bit better."

![](assets/2019_613_page-228.png)

And the fully half-precision version:

```metal
struct Surface {
     half3 baseColor;
     half shininess;
     half roughness;
     half emissive;
};
struct SurfaceRefraction {
     half3 transmission; // transparency
     half indexOfRefraction;
};
```

> "Now we've changed all of our variables to half data types to save even more space. We've reduced our memory usage from 40 to 20 bytes, and rays that don't hit transparent objects will only need 12 bytes."

### Before vs. After

![](assets/2019_613_page-229.png)

Side by side Xcode profiling windows: Before Change and After Change.

> "So how do we understand the performance impact of this? Here we grab GPU traces using the frame capture tool both before and after our change. The most basic version of performance analysis we can do takes place at this phase. By comparing the shader timings in our before and after captures, we can isolate shaders whose performance has changed. Here, we can see that the shader that we've labeled sample surface has gone from 5.5 milliseconds to 4 milliseconds. That's almost a 30 percent savings for one of our more costly shaders. If we want to quantify exactly why we're getting a performance gain, Xcode helpfully displays the results of all the performance counters that it inserts when it does a frame capture. Because we're interested in how we've affected our memory usage, we can take a look at the texture unit statistics and we see that our average texture unit stall time has gone down from 70 percent to 54 percent. And we've reduced our L2 throughput by almost two-thirds. Even more helpfully Xcode will do some analysis of its own and report potential problems to you. Here, it's telling us that our original version had some real problems with memory and that our new version's performing much better. One more tip that you may find useful, is that the compute pipeline state had some interesting telemetry as well. Look at MaxTotalThreadsForThreadgroup. This is an indication of the occupancy of a shader. You should target 1024 as the maximum and anything less means that there may be an occupancy issue that you can fix. So that's debugging in Xcode. It makes developing Ray Tracing and Global Illumination algorithms on the Mac platform incredibly easy. And now, here's Wayne to give you a live demo of all of this."

![](assets/frame_00216.jpg)

---

## Live Demo

![](assets/2019_613_page-230.png)

The Demo title card. Wayne returns for the tram station demo.

![](assets/frame_00222.jpg)

![](assets/frame_00228.jpg)

![](assets/frame_00234.jpg)

![](assets/frame_00240.jpg)

Wayne runs through the scene: MacBook Pro driving four external GPUs, rendering the tram station seen in the State of the Union keynote, everything ray traced in real time.

> "Thanks Matt. So, you may recognize this scene from our platform State of the Union session earlier this week. To render it here, I'm using a MacBook Pro along with four external GPUs. And everything you can see on the screen there is being ray traced in real time. So, I can just take hold of the camera and move around the scene."

![](assets/frame_00246.jpg)

![](assets/frame_00252.jpg)

The hard-to-soft shadow transition from the lamp posts, exactly the effect Wayne described earlier.

> "So, let's start over here. You can see these great shadows that we're getting with Ray Tracing. They're hard at the contact points and they become softer and softer as the distance to the ground increases. And remember, for these shadows we're firing just one ray per pixel and then we're using the Denoiser that Sean was telling us about to get this great filtered result."

![](assets/frame_00258.jpg)

![](assets/frame_00264.jpg)

![](assets/frame_00270.jpg)

Dynamic lighting. Wayne grabs the light and moves it.

> "And this is all calculated dynamically. So, I can just take hold of the light and move it around. And I can see the effect of that pretty much immediately."

![](assets/frame_00276.jpg)

![](assets/frame_00282.jpg)

The tram window reflection. As the light moves, the reflection of the shadow in the glass also moves.

> "There's a really great effect going on here too. If we fly over and look in the window of the tram here, you can actually see the reflections of our shadows, and again, you can see the shadow moving around as I take control of the light."

![](assets/frame_00288.jpg)

![](assets/frame_00294.jpg)

Reflections within reflections: the left tram shows the tram behind it, which in turn shows reflections of its own.

> "And if we head over to this part of the scene now, there's a really great reflection effect going on here. So, if we look at the left most tram you can see the reflection of the tram behind this. But you can also see reflections in the windshield of the tram behind us. So, there's reflections within reflections going on here and we have to simulate a couple of ray bounces per pixel to achieve that effect."

![](assets/frame_00300.jpg)

![](assets/frame_00306.jpg)

Wayne zooms out. The trams move through the scene using two-level acceleration structures.

> "So, I'm going to zoom out here a bit now. And of course, in this scene it's not just the camera and the lights that can move. Sean was telling us about Metal's Two-Level Acceleration structures earlier. And we're using those here to enable the trams to move around the scene."

![](assets/frame_00312.jpg)

![](assets/frame_00318.jpg)

![](assets/frame_00324.jpg)

Up on the roof. Direct sunlight gives way to indirect color-bleeding illumination as Wayne rotates the sun.

> "What I really want to show you now though is this fantastic lighting effect we have going on up on the roof. So, if we focus on the wall on the right there you can see that currently it's being lit primarily by direct sunlight. But as I take control of the sun and I rotate it around you can see the wall falls into shadow and now it's being lit by this really great indirect illumination. So, what's going on here is sunlight is hitting the roof on the left and it's bouncing and illuminating the wall on the right. Giving us this great color bleeding effect."

![](assets/frame_00330.jpg)

![](assets/frame_00336.jpg)

![](assets/frame_00342.jpg)

Dramatic moving shadows as the sun rotates further. Reflections hit the roof on the left side.

> "And if I continue to rotate the sun you can see these really dramatic shadows start to come in and they travel across the surface of the roof there. If I spin the camera around a bit you can really see the reflections as well hitting the roof on the left. So, this is, I really like this shot. There's a lot of Ray Tracing effects all going on at the same time here. We have the indirect illumination, we have the shadows, we have the reflections. And it's all being ray traced in real time with Metal and multi GPU."

![](assets/frame_00348.jpg)

---

## Multi-GPU Tiling

![](assets/2019_613_page-231.png)

Back on slides. Title card: "Interleaved Tiling."

![](assets/2019_613_page-232.png)

The scene divided into a grid of small tiles.

![](assets/2019_613_page-233.png)

Each tile is assigned a color representing which GPU renders it.

> "So, I'm going to switch back to the keynote now and it's this multi GPU aspect that I'd like to talk a bit more about. So, for the demo that we just saw, the way that we implemented multi GPU was by dividing the screen into a set of small tiles and then we mapped these tiles onto the different GPUs. Now in the visualization here I'm using different colors to show you how the tiles are distributed. So, one GPU renders the tiles in red. Another does the tiles in yellow, and so on. And after all GPUs are finished, we just composite those results together to form our final image."

### Load Balancing

![](assets/2019_613_page-234.png)

Four equal quadrants: the naive approach.

> "So, if we take a step back and look at what we have here there's two things that jump out. So firstly, in the image on the left, so the way that we're assigning tiles to GPUs, it looks a bit strange. So why are we doing it like that? And secondly, for those small tiles the implication of that is that each GPU is going to render a block of pixels there and then a block of pixels somewhere else. And that just feels like it's going to be bad for things like ray coherency, cache hit ratios. All that kind of stuff. So, let's deal with these in turn. So, imagine we have four GPUs. The simple way to do multi GPU here is just to split the screen into quadrants."

![](assets/2019_613_page-235.png)

The quadrants are subdivided once.

> "Now the issue with that is that some parts of a scene will be much easier to render than others. So, if we assume that the street and the building on the left there are much easier to render than the tram on the right. It stands to reason that the red and yellow GPUs will finish before the green and purple GPUs. Now we can fix this just by splitting the screen into smaller tiles."

![](assets/2019_613_page-236.png)

And subdivided again.

> "Then we can split each of those into smaller tiles and so on. Until we reach some minimum tile size. Now this has the effect of distributing work really evenly across the GPUs."

![](assets/2019_613_page-237.png)

A fully small-tiled grid, with a pseudo-random assignment scheme.

> "So, if one part of the screen is particularly difficult to render, it just doesn't matter, because every GPU will be assigned tiles from that part of the screen. Now in practice, this regular tiling pattern that you see here probably isn't the way to go. Because you can get cases where the tiling aligns with the geometry in your scene. And so, we randomize a bit."

![](assets/2019_613_page-238.png)

"Pseudo-random assignment avoids correlation with the scene."

![](assets/2019_613_page-239.png)

"Same GPU renders the same tiles each frame."

> "And one of the really interesting things about this approach is that the mapping of tiles to GPUs, it does not change. So, the same GPU will process the same tiles every frame. And this is great. So, you can just calculate that mapping when your application initializes or when you resize the window and that's it. You don't need to think about multi GPU load balancing anymore and there's nothing to monitor. Nothing to recalculate in your application's main loop."

![](assets/frame_00354.jpg)

### Choosing a Tile Size

![](assets/2019_613_page-240.png)

"How small should I make my tiles? Experiment: vary tile size, measure performance."

> "So, if we know that small tiles distribute the work more evenly, why not just take it to the extreme and make them a pixel. So, the problem with that is that we need to give each GPU nice coherent blocks of pixels to be working on. So, the tradeoff there between balancing the load evenly and making sure that each GPU can run as efficiently as possible. So, to better understand that tradeoff we did a simple experiment."

![](assets/2019_613_page-241.png)

A chart: Relative Performance vs. Tile Size. The X axis lists 1x1, 2x2, 4x4, 8x8, 16x16, 32x32, 256x256, 512x512. Performance is low at the extremes and plateaus near 1.0 through most of the middle.

> "We took one of the new Mac Pros with a pair of the Vega II Duo GPUs, so that's four GPUs in total, and we tried rendering the same scene with various tiles sizes to see how that effected performance. Now of course, your mileage may vary here, but what we found is that the performance window is actually really wide. So, efficiency drops off if you make your tiles very small or if you make them very, very large. But anywhere in the middle keeps us pretty close to peak performance."

### Tile Assignment

![](assets/2019_613_page-242.png)

- Assign each tile a random number
- Compare against thresholds to pick GPU

A bar splits 0.0 to 1.0 into four equal GPU ranges: 0.0-0.25 GPU 0, 0.25-0.5 GPU 1, 0.5-0.75 GPU 2, 0.75-1.0 GPU 3.

> "So now we have our tile size pinned down, what we need to do next is assign them to the various GPUs. Now to do this, we start by generating a random number for each tile and then we compare those random numbers to a set of thresholds. And whichever range the random number lands in, that gives us the GPU to use for that tile."

![](assets/2019_613_page-243.png)

![](assets/2019_613_page-244.png)

![](assets/2019_613_page-245.png)

![](assets/2019_613_page-246.png)

A 4x4 tile grid is populated with example random numbers: 0.4, 0.55, 0.22, 0.78 / 0.64, 0.12, 0.35, 0.89 / 0.1, 0.39, 0.72, 0.61 / 0.79, 0.2, 0.9, 0.42. Each tile's number is compared to the thresholds and distributed to the GPU buckets.

> "So as an example, here, if the random number is .4, we assign it to GPU 1. If it's .55, it goes on GPU 2. And so on."

![](assets/2019_613_page-247.png)

![](assets/2019_613_page-248.png)

All tiles are distributed to the four buckets.

> "Now, once we've done this for every tile the output is a list of tiles that we need each GPU to render."

![](assets/2019_613_page-249.png)

"Adjust ranges to control distribution." The thresholds bar appears with equal 0.25 bins.

![](assets/2019_613_page-250.png)

The thresholds are adjusted to be unequal: GPU 0 gets 0.0-0.15, GPU 1 gets 0.15-0.4, GPU 2 gets 0.4-0.8, GPU 3 gets 0.8-1.0. GPU 2 now gets a much larger share.

> "As you can see down the bottom there the ranges that we're using for each GPU are equal. So, when assigning tiles to GPUs they are all equally likely to be chosen. But in practice, you almost certainly don't want this. For example, you might need to reserve capacity on one of your GPUs for non-ray tracing tasks such as denoising or tone mapping. Or you might be using GPUs with different performance. In which case you'll want to send more tiles to the more powerful GPUs. And you can account for this really easily by just adjusting the ranges."

![](assets/2019_613_page-251.png)

The same example random numbers are assigned using the new thresholds, visibly reassigning tiles to GPU 2.

> "So now if we go ahead and reassign the same tiles we used before, you can see here that now GPU 2 takes on a much greater share of the work."

![](assets/frame_00360.jpg)

### Data Transfers

![](assets/2019_613_page-252.png)

A block diagram: CPU connected to four GPUs in the AMD Radeon Pro Vega II Duo, one of which drives the Display.

> "Now, for the actual implantation of this there was a lot of really useful information in our Metal for Pro Apps session earlier this week. So, I won't go over that again here. But it is definitely useful to highlight just a couple of areas that can have a really big impact on performance. So firstly, you'll probably want to composite your tiles together on the GPU that's driving the display. So, it's important to find out which GPU that is and then work backwards to figure out how to get your data there efficiently."

![](assets/2019_613_page-253.png)

Infinity Fabric Link is added between the GPUs.

> "So, if the GPUs are in the same peer group then you can copy between them directly using our new peer group APIs."

![](assets/2019_613_page-254.png)

PCIe links are added between the CPU and each GPU.

> "Otherwise you'll need to go by the CPU."

![](assets/frame_00366.jpg)

### Scheduling Across GPUs

![](assets/2019_613_page-255.png)

A timeline diagram with two GPUs. GPU 0 does back-to-back ray tracing for frames 0, 1, and 2. GPU 1 ray traces frame 0.

> "Now secondly, it can often take a few milliseconds to copy data between GPUs and we definitely don't want to block waiting for those transfers to complete. So, to give you an example of how we're dealing with that we have two GPUs here and we're using the tiling scheme that I was just talking about to spread the rendering across the two GPUs. Now in GPU 0 at the top there we have two queues. One is just flat out doing back-to-back Ray Tracing. And then we have a second queue that copies the completed tiles over to GPU 1 asynchronously."

![](assets/2019_613_page-256.png)

GPU 0 begins the second queue operation: Copy tiles for frame 0 runs concurrently with rendering frame 1.

![](assets/2019_613_page-257.png)

GPU 1 continues to frame 1's ray tracing while tiles from frame 0 flow in.

![](assets/2019_613_page-258.png)

GPU 1 starts a Composite step for frame 0 once its tiles are present.

> "Now, we'll assume that GPU 1 at the bottom there is the one that's driving our display. And here things are a bit different. This GPU is also Ray Tracing part of frame 0, but we can't go ahead and present that frame until the rest of our tiles have been copied over from the other GPU. So rather than wait, we just start work on the next frame. And then a bit later on when our tiles arrive from the other GPU, that's when we go ahead and composite everything together."

![](assets/2019_613_page-259.png)

The fully steady-state pipeline: GPU 0 renders frame N, GPU 1 renders frame N and composites frame N-1.

> "So, I'll show you that one more time here. So, you can see that we end up in this steady state where we render frame N and then we composite frame N minus 1. So essentially, what we're doing here is latency hiding. And this together with the tiling scheme I was showing you to load balance between the GPUs, this is enabling us to achieve really great performance for our Ray Tracing workloads on our multi GPU systems."

![](assets/frame_00372.jpg)

![](assets/frame_00378.jpg)

---

## Summary

![](assets/2019_613_page-260.png)

The summary slide lists:

- Ray/triangle intersection
- Dynamic scenes
- MPSSVGFDenoiser
- Use cases
- Multi-GPU

> "And with that, we come to the end of the talk. We began with a quick refresher of how Ray Tracing works in Metal and then we focused on a few features of the MPSRayIntersector that are there to really help with dynamic scenes. So that's the Two-Level Acceleration Structures along with our GPU Accelerated Rebuilds and Refitting. We also introduced the new Metal Denoiser. And then we talked through a few Ray Tracing use cases such as Shadows, Ambient Occlusion, and Global Illumination. When then showed you how to debug and profile Ray Tracing workloads using Xcode. And then, we finished by talking about how to take advantage of multiple GPUs in your Ray Tracing applications."

## More Information

![](assets/2019_613_page-261.png)

The slide points to [developer.apple.com/wwdc19/613](https://developer.apple.com/wwdc19/613).

> "Now, for more information be sure to visit developer.apple.com and there you'll also find a new sample demonstrating some of the features that we've talked about today."

## Related Sessions

![](assets/2019_613_page-262.png)

- Metal for Machine Learning and Ray Tracing Lab, Friday, 12:00

![](assets/2019_613_page-263.png)

- Metal for Machine Learning Session, Friday, 3:20

> "If you're new to Ray Tracing be sure to check out our talk from last year. And finally, we have our lab session coming up next at 12. So, I hope you can join us for that. So, thank you all for coming and I'll see you in the lab shortly."

![](assets/frame_00384.jpg)

![](assets/frame_00390.jpg)

![](assets/frame_00396.jpg)

---

## Appendix: Additional Demo Frames

The multi-GPU tram station demo showcases every technique covered in the session in real time. Additional angles from the live render:

![](assets/frame_00402.jpg)

A wide shot of the station showing dynamic shadows from the trams.

![](assets/frame_00408.jpg)

A close-up on a pillar base where the soft shadow gradient is visible.

![](assets/frame_00414.jpg)

Overhead view emphasizing the global illumination bounce light on the rear wall.

![](assets/frame_00420.jpg)

Tram window with a reflection-within-reflection.

![](assets/frame_00426.jpg)

Sun position near the horizon, raking shadows across the station floor.

![](assets/frame_00432.jpg)

Light from the sun bouncing off the roof to illuminate the indoor wall.

![](assets/frame_00438.jpg)

Geometry transition as the tram enters the view.

![](assets/frame_00444.jpg)

Reflected shadow moving on the glass of the tram window.

![](assets/frame_00450.jpg)

Detailed ambient occlusion visible under the bench seats on the platform.

![](assets/frame_00456.jpg)

Wayne moving the sun, the whole scene relights in real time.

![](assets/frame_00462.jpg)

Color-bleeding onto the ceiling from the warm-toned floor.

![](assets/frame_00468.jpg)

Soft contact shadows at the base of a pillar.

![](assets/frame_00474.jpg)

Dramatic shadow sweeping across the roof as the sun rotates.

![](assets/frame_00480.jpg)

Another reflection-within-a-reflection angle.

![](assets/frame_00486.jpg)

The bench detail lit entirely by indirect illumination.

![](assets/frame_00492.jpg)

Wide angle showing the full station at low sun angle.

![](assets/frame_00498.jpg)

A signage detail near the platform edge.

![](assets/frame_00504.jpg)

Tram roof detail showing the specular highlights from the sunlight.

![](assets/frame_00510.jpg)

Column base shadow illustrating the hard-to-soft gradient.

![](assets/frame_00516.jpg)

Ray-traced reflections on the metallic overhead wiring.

![](assets/frame_00522.jpg)

Far end of the platform with heavy shadow coverage.

![](assets/frame_00528.jpg)

Final summary views as Wayne wraps up the demo.

![](assets/frame_00534.jpg)

![](assets/frame_00540.jpg)

![](assets/frame_00546.jpg)

![](assets/frame_00552.jpg)

![](assets/frame_00558.jpg)

![](assets/frame_00564.jpg)

![](assets/frame_00570.jpg)

![](assets/frame_00576.jpg)

![](assets/frame_00582.jpg)

![](assets/frame_00588.jpg)

![](assets/frame_00594.jpg)

![](assets/frame_00600.jpg)

---

## Key Takeaways

The core API surface for ray tracing in Metal as of 2019:

1. **`MPSRayIntersector`** encodes ray-triangle intersection work into a Metal command buffer. Inputs: a ray buffer, an acceleration structure. Outputs: an intersection buffer.
2. **`MPSTriangleAccelerationStructure`** wraps a bottom-level BVH over a single geometry's triangles.
3. **`MPSInstanceAccelerationStructure`** wraps a top-level BVH over references into one or more `MPSTriangleAccelerationStructure`s, each with a transformation matrix, enabling rigid-body animation without rebuilding bottom levels.
4. **`MPSAccelerationStructureGroup`** ties together acceleration structures that will be used together.
5. **Refitting** (`accelerationStructure.usage = .refit`, then `encodeRefit(commandBuffer:)`) updates bounding boxes bottom-up on the GPU for vertex-animated / skinned geometry.
6. **`MPSSVGFDenoiser`** coordinates the SVGF denoising algorithm. **`MPSSVGF`** provides low-level kernel access. **`MPSSVGFTextureAllocator`** lets you share temporary texture memory with your app.
7. **Indirect dispatch** feeds a ray count buffer into `encodeIntersection` and `dispatchThreadgroups(indirectBuffer:...)` so compaction output drives the next pass.

Shader-level optimization advice the speakers emphasized:

- Use block-linear (8x8) ray buffer ordering rather than row-linear for cache coherency.
- Disable rays with `maxDistance < 0.0` rather than skipping pixels in shader control flow.
- Use cosine sampling over hemisphere sampling for ambient occlusion.
- Use Halton (2, 3) or similar low-discrepancy sequences for ray distributions.
- Apply per-pixel blue-noise deltas to decorrelate neighboring pixels.
- Split material structs so transparent-only data does not pay bandwidth cost for opaque-hit rays.
- Pack to `half` / `packed_half3` where precision permits.
- Use Metal argument buffers to bind scene-wide material arrays when texture bind slots run out.
- Compact ray buffers with an `atomic_fetch_add_explicit` counter, then dispatch with the counter as the ray count.

Multi-GPU guidance from the final section:

- Interleave small pseudo-random tiles across GPUs rather than subdividing the screen into quadrants.
- The tile-to-GPU mapping is static per window size. Calculate once, reuse every frame.
- Sweet spot tile size is well inside the middle range on four-GPU Vega II Duo setups.
- Use peer-group copies over Infinity Fabric when available; otherwise route through the CPU.
- Hide copy latency by starting frame N ray tracing on the display GPU while tiles from frame N-1 finish copying in, then composite.

---

*This document transcribes every slide page of PDF (001 through 263) and samples frames across the full 58 minute video. Code blocks are reproduced verbatim from the slides. Speaker prose is captured from the session transcript.*
