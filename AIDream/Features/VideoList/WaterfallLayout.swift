import UIKit

protocol WaterfallLayoutDelegate: AnyObject {
    func collectionView(_ collectionView: UICollectionView, heightForItemAt indexPath: IndexPath, with width: CGFloat) -> CGFloat
    func collectionView(_ collectionView: UICollectionView, columnSpanForItemAt indexPath: IndexPath) -> Int
    func collectionView(_ collectionView: UICollectionView, heightForFullWidthItemAt indexPath: IndexPath, with width: CGFloat) -> CGFloat
}

class WaterfallLayout: UICollectionViewLayout {
    weak var delegate: WaterfallLayoutDelegate?

    private let numberOfColumns = 2
    private let cellPadding: CGFloat = 8
    private var cache: [UICollectionViewLayoutAttributes] = []
    private var contentHeight: CGFloat = 0

    private var contentWidth: CGFloat {
        guard let collectionView = collectionView else { return 0 }
        let insets = collectionView.contentInset
        // 确保在手机屏幕上留出足够的侧边距
        return collectionView.bounds.width - (insets.left + insets.right + 24)
    }

    override var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth + 24, height: contentHeight)
    }

    // 关键修复：当数据变化时清除缓存
    override func invalidateLayout() {
        super.invalidateLayout()
        cache.removeAll()
        contentHeight = 0
    }

    override func prepare() {
        // 如果缓存不为空，直接使用
        guard cache.isEmpty, let collectionView = collectionView else { return }

        let columnWidth = contentWidth / CGFloat(numberOfColumns)
        var xOffset: [CGFloat] = []
        for column in 0..<numberOfColumns {
            xOffset.append(CGFloat(column) * columnWidth + 12)
        }

        var column = 0
        var yOffset: [CGFloat] = Array(repeating: 0, count: numberOfColumns)

        for item in 0..<collectionView.numberOfItems(inSection: 0) {
            let indexPath = IndexPath(item: item, section: 0)
            let span = max(1, min(numberOfColumns, delegate?.collectionView(collectionView, columnSpanForItemAt: indexPath) ?? 1))

            if span == numberOfColumns {
                let width = contentWidth - cellPadding * 2
                let photoHeight = delegate?.collectionView(collectionView, heightForFullWidthItemAt: indexPath, with: width) ?? 220
                let height = cellPadding * 2 + photoHeight
                let topY = max(yOffset[0], yOffset[1])
                let frame = CGRect(x: 12, y: topY, width: contentWidth, height: height)
                let insetFrame = frame.insetBy(dx: cellPadding, dy: cellPadding)

                let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                attributes.frame = insetFrame
                cache.append(attributes)

                let newY = frame.maxY
                yOffset[0] = newY
                yOffset[1] = newY
                contentHeight = max(contentHeight, newY)
                column = yOffset[0] <= yOffset[1] ? 0 : 1
                continue
            }

            let width = columnWidth - cellPadding * 2
            let photoHeight = delegate?.collectionView(collectionView, heightForItemAt: indexPath, with: width) ?? 180
            let height = cellPadding * 2 + photoHeight

            let frame = CGRect(x: xOffset[column], y: yOffset[column], width: columnWidth, height: height)
            let insetFrame = frame.insetBy(dx: cellPadding, dy: cellPadding)

            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = insetFrame
            cache.append(attributes)

            contentHeight = max(contentHeight, frame.maxY)
            yOffset[column] = yOffset[column] + height

            // 智能选择最短的那一列来放置下一个 item，防止瀑布流两边高度差过大
            column = yOffset[0] <= yOffset[1] ? 0 : 1
        }
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return cache.filter { $0.frame.intersects(rect) }
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cache.indices.contains(indexPath.item) ? cache[indexPath.item] : nil
    }
}
