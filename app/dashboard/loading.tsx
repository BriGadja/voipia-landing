export default function Loading() {
  return (
    <div className="min-h-screen p-6 max-w-[1600px] mx-auto">
      <div className="mb-8 animate-pulse">
        <div className="h-10 w-64 bg-white/10 rounded mb-2" />
        <div className="h-6 w-96 bg-white/10 rounded" />
      </div>

      <div className="mb-8 p-6 bg-black/20 border border-white/20 rounded-xl">
        <div className="h-32 bg-white/10 rounded animate-pulse" />
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        {[...Array(7)].map((_, i) => (
          <div
            key={i}
            className="h-32 bg-black/20 border border-white/20 rounded-xl animate-pulse"
          />
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {[...Array(4)].map((_, i) => (
          <div
            key={i}
            className="h-96 bg-black/20 border border-white/20 rounded-xl animate-pulse"
          />
        ))}
      </div>
    </div>
  )
}
