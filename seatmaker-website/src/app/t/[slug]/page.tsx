import Viewer from "../../t/viewer";

export default function Page({ params }: { params: { slug: string } }) {
  return <Viewer slug={params.slug} />;
}


