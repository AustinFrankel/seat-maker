import Image from "next/image";

export function DeviceMockups() {
  return (
    <div className="relative mx-auto grid grid-cols-2 sm:grid-cols-3 md:grid-cols-5 gap-4 max-w-5xl [perspective:1000px]">
      {[1, 2, 3, 4, 5].map((n) => (
        <div key={n} className="relative aspect-[9/16] rounded-xl overflow-hidden bg-muted will-change-transform transition-transform hover:[transform:rotateX(6deg)_translateY(-2px)]">
          <Image
            src={`/images/seat${n}_bg.png`}
            alt={`Seat Maker mockup ${n}`}
            fill
            sizes="(max-width: 768px) 50vw, 20vw"
            className="object-contain"
            priority={n === 3}
          />
        </div>
      ))}
    </div>
  );
}


