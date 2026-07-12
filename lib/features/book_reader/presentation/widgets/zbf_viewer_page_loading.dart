part of 'zbf_viewer_page.dart';

class _ViewerLoading extends StatelessWidget {
  const _ViewerLoading();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(leading: const BackButton()),

    backgroundColor: context.colors.paper,
    body: const ReaderPageLoading(message: 'Opening…'),
  );
}
