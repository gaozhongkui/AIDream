import UIKit

protocol WaterfallLayoutDelegate: AnyObject {
    func collectionView(_ collectionView: UICollectionView, heightForItemAt indexPath: IndexPath, with width: CGFloat) -> CGFloat
    func collectionView(_ collectionView: UICollectionView, columnSpanForItemAt indexPath: IndexPath) -> Int
    func collectionView(_ collectionView: UICollectionView, heightForFullWidthItemAt indexPath: IndexPath, with width: CGFloat) -> CGFloat
    func collectionView(_ collectionView: UICollectionView, heightForFooterIn section: Int, contentHeight: CGFloat, availableHeight: CGFloat) -> CGFloat
}

class WaterfallLayout: UICollectionViewLayout {
    weak var delegate: WaterfallLayoutDelegate?

    private let numberOfColumns = 2
    private let cellPadding: CGFloat = 8
    private let columnSpacing: CGFloat = 8
    private var cache: [UICollectionViewLayoutAttributes] = []
    private var footerAttributes: UICollectionViewLayoutAttributes?
    private var contentHeight: CGFloat = 0

    private var contentWidth: CGFloat {
        guard let collectionView = collectionView else { return 0 }
        let insets = collectionView.contentInset
        return collectionView.bounds.width - (insets.left + insets.right)
    }

    override var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth, height: contentHeight)
    }

    override func invalidateLayout() {
        super.invalidateLayout()
        cache.removeAll()
        footerAttributes = nil
        contentHeight = 0
    }

    override func prepare() {
        guard cache.isEmpty, let collectionView = collectionView else { return }

        let totalSpacing = columnSpacing * CGFloat(numberOfColumns - 1)
        let columnWidth = (contentWidth - totalSpacing) / CGFloat(numberOfColumns)

        var xOffset: [CGFloat] = []
        for column in 0..<numberOfColumns {
            xOffset.append(CGFloat(column) * (columnWidth + columnSpacing))
        }

        var column = 0
        var yOffset: [CGFloat] = Array(repeating: 0, count: numberOfColumns)

        for item in 0..<collectionView.numberOfItems(inSection: 0) {
            let indexPath = IndexPath(item: item, section: 0)
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
            column = yOffset[0] <= yOffset[1] ? 0 : 1
        }

        let availableHeight = collectionView.bounds.height - collectionView.adjustedContentInset.top - collectionView.adjustedContentInset.bottom
        let footerHeight = delegate?.collectionView(collectionView, heightForFooterIn: 0, contentHeight: contentHeight, availableHeight: availableHeight) ?? 0
        if footerHeight > 0 {
            let footerFrame = CGRect(x: 0, y: contentHeight, width: contentWidth, height: footerHeight)
            footerAttributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, with: IndexPath(item: 0, section: 0))
            footerAttributes?.frame = footerFrame
            contentHeight += footerHeight
        }
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var visibleLayoutAttributes: [UICollectionViewLayoutAttributes] = []
        for attributes in cache {
            if attributes.frame.intersects(rect) {
                visibleLayoutAttributes.append(attributes)
            }
        }
        if let footerAttrs = footerAttributes, footerAttrs.frame.intersects(rect) {
            visibleLayoutAttributes.append(footerAttrs)
        }
        return visibleLayoutAttributes
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cache.indices.contains(indexPath.item) ? cache[indexPath.item] : nil
    }

    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if elementKind == UICollectionView.elementKindSectionFooter {
            return footerAttributes
        }
        return nil
    }
}
