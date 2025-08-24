import Image from "next/image";
import Img24 from "../../../images/Untitled design (24).png";
import Img25 from "../../../images/Untitled design (25).png";
import Img26 from "../../../images/Untitled design (26).png";
import Img27 from "../../../images/Untitled design (27).png";
import Img28 from "../../../images/Untitled design (28).png";

export function DesignStrip() {
  const items = [
    { src: Img24, alt: "Seat Maker concept 24" },
    { src: Img25, alt: "Seat Maker concept 25" },
    { src: Img26, alt: "Seat Maker concept 26" },
    { src: Img27, alt: "Seat Maker concept 27" },
    { src: Img28, alt: "Seat Maker concept 28" },
  ];
  return (
    <section aria-label="Design showcase" className="py-16">
      <div className="mx-auto max-w-6xl px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-5 gap-4 [perspective:1000px]">
          {items.map(({ src, alt }, i) => (
            <div key={i} className="relative aspect-[4/3] rounded-xl overflow-hidden bg-muted will-change-transform transition-transform hover:[transform:rotateX(6deg)_translateY(-2px)]">
              <Image src={src} alt={alt} fill sizes="(max-width: 768px) 50vw, 20vw" className="object-cover" />
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}


