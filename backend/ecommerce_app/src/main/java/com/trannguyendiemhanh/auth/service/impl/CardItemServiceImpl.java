package com.trannguyendiemhanh.auth.service.impl;

import com.trannguyendiemhanh.auth.dto.CartItemRequest;
import com.trannguyendiemhanh.auth.dto.CartItemResponse;
import com.trannguyendiemhanh.auth.entity.Card;
import com.trannguyendiemhanh.auth.entity.CardItem;
import com.trannguyendiemhanh.auth.entity.StaffAccount;
import com.trannguyendiemhanh.auth.repository.CardRepository;
import com.trannguyendiemhanh.auth.repository.CardItemRepository;
import com.trannguyendiemhanh.auth.repository.StaffAccountRepository;
import com.trannguyendiemhanh.auth.service.CardItemService;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
public class CardItemServiceImpl extends JpaCrudServiceImpl<CardItem, UUID> implements CardItemService {
    private final CardItemRepository cardItemRepository;
    private final CardRepository cardRepository;
    private final StaffAccountRepository staffAccountRepository;

    public CardItemServiceImpl(
            CardItemRepository repository,
            CardRepository cardRepository,
            StaffAccountRepository staffAccountRepository
    ) {
        super(repository);
        this.cardItemRepository = repository;
        this.cardRepository = cardRepository;
        this.staffAccountRepository = staffAccountRepository;
    }

    @Override
    public CartItemResponse addToCart(CartItemRequest request) {
        UUID accountId = UUID.fromString(request.getAccountId());
        StaffAccount account = staffAccountRepository.findById(accountId)
                .orElseThrow(() -> new RuntimeException("Account not found with ID: " + accountId));

        Card card = cardRepository.findByAccountId(accountId)
                .orElseGet(() -> cardRepository.save(Card.builder().account(account).build()));

        String size = defaultText(request.getSize(), "S");
        String color = defaultText(request.getColor(), "Black");
        String productKey = defaultText(request.getProductKey(), request.getProductName());
        int quantity = request.getQuantity() == null || request.getQuantity() < 1
                ? 1
                : request.getQuantity();

        CardItem item = cardItemRepository
                .findByCardIdAndProductKeyAndSizeAndColor(card.getId(), productKey, size, color)
                .map(existing -> {
                    existing.setQuantity((existing.getQuantity() == null ? 0 : existing.getQuantity()) + quantity);
                    return existing;
                })
                .orElseGet(() -> CardItem.builder()
                        .card(card)
                        .productKey(productKey)
                        .productName(defaultText(request.getProductName(), "Product"))
                        .brand(defaultText(request.getBrand(), "Fashion"))
                        .image(defaultText(request.getImage(), ""))
                        .price(request.getPrice() == null ? 0 : request.getPrice())
                        .oldPrice(request.getOldPrice())
                        .discountPercent(request.getDiscountPercent())
                        .rating(request.getRating() == null ? 0 : request.getRating())
                        .reviews(request.getReviews() == null ? 0 : request.getReviews())
                        .size(size)
                        .color(color)
                        .quantity(quantity)
                        .build());

        return CartItemResponse.fromEntity(cardItemRepository.save(item));
    }

    @Override
    public List<CartItemResponse> getCartItems(UUID accountId) {
        return cardItemRepository.findByCardAccountIdOrderById(accountId)
                .stream()
                .map(CartItemResponse::fromEntity)
                .toList();
    }

    private String defaultText(String value, String fallback) {
        return value == null || value.trim().isEmpty() ? fallback : value.trim();
    }
}
