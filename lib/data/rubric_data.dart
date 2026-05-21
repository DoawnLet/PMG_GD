import '../models/rubric.dart';

const pmg201cRubric = Rubric(
  examTitle: 'PMG201c - Practical Exam 2 (Spring 2026)',
  requests: [
    RequestRubric(
      number: 1,
      title: 'Phát biểu điều lệ dự án (Project Charter Statement)',
      maxPoints: 20,
      criteria: [
        Criterion(
          id: '1.1', name: 'Tên dự án rõ ràng và phù hợp', maxPoints: 2,
          fullDesc: 'Tên đầy đủ, rõ ràng, phản ánh đúng bản chất dự án trong tình huống',
          acceptDesc: 'Tên có nhưng còn chung chung hoặc không khớp ngữ cảnh',
          failDesc: 'Không có tên hoặc tên không liên quan',
        ),
        Criterion(
          id: '1.2', name: 'Lý do triển khai (vấn đề / cơ hội)', maxPoints: 4,
          fullDesc: 'Nêu rõ ít nhất 2 lý do cụ thể: vấn đề hiện tại + cơ hội / yêu cầu pháp lý / chiến lược tổ chức, dẫn chứng từ đề bài',
          acceptDesc: 'Nêu được 1 lý do hoặc còn mơ hồ, thiếu bối cảnh',
          failDesc: 'Không nêu lý do hoặc sao chép nguyên văn đề bài không có diễn giải',
        ),
        Criterion(
          id: '1.3', name: 'Mục đích dự án (mong đợi đạt được)', maxPoints: 4,
          fullDesc: 'Phát biểu rõ kết quả mong muốn, đối tượng thụ hưởng, và lợi ích cốt lõi',
          acceptDesc: 'Có mục đích nhưng thiếu 1 trong 3 yếu tố trên',
          failDesc: 'Mục đích mơ hồ hoặc lẫn với lý do',
        ),
        Criterion(
          id: '1.4', name: 'Ràng buộc phạm vi (Scope constraint)', maxPoints: 3,
          fullDesc: 'Chỉ rõ những gì TRONG và NGOÀI phạm vi dự án, có ví dụ cụ thể',
          acceptDesc: 'Nêu phạm vi nhưng không phân biệt in/out scope',
          failDesc: 'Phạm vi quá rộng / không rõ ràng',
        ),
        Criterion(
          id: '1.5', name: 'Ràng buộc thời gian (Time constraint)', maxPoints: 3,
          fullDesc: 'Thời hạn cụ thể (tháng/năm), có thể kèm mốc quan trọng đầu tiên',
          acceptDesc: 'Có hạn chót nhưng không xác định rõ điểm mốc',
          failDesc: 'Không có thông tin thời gian',
        ),
        Criterion(
          id: '1.6', name: 'Ràng buộc chi phí (Cost constraint)', maxPoints: 2,
          fullDesc: 'Nêu đúng ngân sách từ đề bài, có phân loại hoặc ghi chú nguồn tài trợ',
          acceptDesc: 'Có ngân sách nhưng không chính xác hoặc không có đơn vị',
          failDesc: 'Không có thông tin chi phí',
        ),
        Criterion(
          id: '1.7', name: 'Ràng buộc chất lượng (Quality constraint)', maxPoints: 2,
          fullDesc: 'Nêu ít nhất 1 chỉ tiêu chất lượng đo lường được từ đề bài',
          acceptDesc: 'Có đề cập chất lượng nhưng không đo lường được',
          failDesc: 'Không đề cập chất lượng',
        ),
      ],
      commonErrors: [
        'Viết charter dưới dạng bullet list ngắn, không có dạng văn tường thuật (narrative)',
        'Lẫn lộn Justification (lý do tại sao làm) với Objective (mục tiêu đạt được)',
        'Ràng buộc chất lượng bị bỏ qua hoặc chỉ ghi "đảm bảo chất lượng" chung chung',
        'Không sử dụng con số cụ thể từ đề bài (ngân sách, thời hạn, chỉ tiêu)',
      ],
    ),
    RequestRubric(
      number: 2,
      title: 'Kế hoạch chi phí / ngân sách dự án',
      maxPoints: 20,
      criteria: [
        Criterion(
          id: '2.1', name: 'Số lượng hạng mục (tối thiểu 5)', maxPoints: 3,
          fullDesc: '>=5 hạng mục chi phí riêng biệt, không trùng lặp',
          acceptDesc: '4 hạng mục',
          failDesc: '<4 hạng mục hoặc nhiều hạng mục trùng lặp',
        ),
        Criterion(
          id: '2.2', name: 'Tên và mô tả hạng mục rõ ràng', maxPoints: 4,
          fullDesc: 'Tên rõ ràng, mô tả giải thích nội dung chi tiết hạng mục và lý do phát sinh',
          acceptDesc: 'Tên rõ nhưng mô tả sơ sài',
          failDesc: 'Tên quá chung hoặc không có mô tả',
        ),
        Criterion(
          id: '2.3', name: 'Phương pháp ước lượng hợp lý', maxPoints: 5,
          fullDesc: 'Sử dụng kỹ thuật phù hợp (Analogous, Parametric, Bottom-up, Three-point), giải thích cơ sở ước tính',
          acceptDesc: 'Có phương pháp nhưng không giải thích hoặc chỉ "tham khảo thị trường"',
          failDesc: 'Không có phương pháp hoặc chỉ ước đoán tùy ý',
        ),
        Criterion(
          id: '2.4', name: 'Con số ước lượng cụ thể (có đơn vị)', maxPoints: 4,
          fullDesc: 'Số cụ thể (VND / USD), tổng phù hợp với ngân sách đề bài',
          acceptDesc: 'Có số nhưng thiếu đơn vị hoặc tổng vượt/thấp hơn nhiều so với đề bài',
          failDesc: 'Không có con số cụ thể',
        ),
        Criterion(
          id: '2.5', name: 'Người phụ trách từng hạng mục', maxPoints: 4,
          fullDesc: 'Gán vai trò/bộ phận cụ thể cho từng hạng mục, phù hợp logic dự án',
          acceptDesc: 'Gán người phụ trách nhưng tất cả cùng 1 vai trò',
          failDesc: 'Không có người phụ trách',
        ),
      ],
      commonErrors: [
        'Ước lượng tổng ngân sách vượt quá hoặc thiếu hơn nhiều so với ngân sách trong đề bài',
        'Phương pháp ước lượng chỉ ghi "dựa vào kinh nghiệm" mà không có cơ sở cụ thể',
        'Gộp nhiều loại chi phí khác nhau vào một hạng mục',
        'Không có contingency reserve (dự phòng rủi ro) trong danh sách',
      ],
    ),
    RequestRubric(
      number: 3,
      title: 'Đăng ký rủi ro dự án (Risk Register)',
      maxPoints: 30,
      criteria: [
        Criterion(
          id: '3.1', name: 'Số lượng rủi ro (tối thiểu 3)', maxPoints: 3,
          fullDesc: '>=3 rủi ro, mỗi rủi ro có tên riêng biệt',
          acceptDesc: '2 rủi ro',
          failDesc: '<2 rủi ro hoặc rủi ro trùng lặp',
        ),
        Criterion(
          id: '3.2', name: 'Mô tả rủi ro rõ ràng (điều kiện + hậu quả)', maxPoints: 6,
          fullDesc: 'Dùng cấu trúc "Nếu [điều kiện] thì [hậu quả]", cụ thể theo ngữ cảnh dự án',
          acceptDesc: 'Có mô tả nhưng thiếu điều kiện hoặc hậu quả',
          failDesc: 'Mô tả chung chung, không liên quan dự án',
        ),
        Criterion(
          id: '3.3', name: 'Tác động đến phạm vi/chất lượng, thời gian, chi phí', maxPoints: 9,
          fullDesc: 'Phân tích đủ 3 chiều tác động cho từng rủi ro: S/Q, T, C, có ước lượng mức độ hoặc ví dụ',
          acceptDesc: 'Phân tích đủ nhưng không có ước lượng/mức độ',
          failDesc: 'Chỉ nêu 1-2 chiều hoặc bỏ qua hoàn toàn',
        ),
        Criterion(
          id: '3.4', name: 'Kế hoạch giảm nhẹ rủi ro (Mitigation)', maxPoints: 6,
          fullDesc: 'Hành động phòng ngừa cụ thể, thực hiện TRƯỚC khi rủi ro xảy ra, gán trách nhiệm',
          acceptDesc: 'Có hành động nhưng thực ra là xử lý sau (contingency)',
          failDesc: 'Không có hoặc quá chung chung',
        ),
        Criterion(
          id: '3.5', name: 'Kế hoạch dự phòng (Contingency)', maxPoints: 6,
          fullDesc: 'Hành động phản ứng cụ thể KHI rủi ro đã xảy ra, khác hoàn toàn với mitigation',
          acceptDesc: 'Có phản ứng nhưng giống mitigation',
          failDesc: 'Không có hoặc chỉ ghi "báo cáo lên cấp trên"',
        ),
      ],
      commonErrors: [
        'Lẫn lộn Mitigation (phòng ngừa, trước khi xảy ra) và Contingency (xử lý, sau khi xảy ra)',
        'Rủi ro quá chung chung không chỉ rõ nguyên nhân cụ thể',
        'Tác động chỉ ghi "làm chậm dự án" mà không lượng hóa',
        'Mô tả rủi ro và tác động bị lẫn vào nhau',
      ],
    ),
    RequestRubric(
      number: 4,
      title: 'Ma trận RACI',
      maxPoints: 30,
      criteria: [
        Criterion(
          id: '4.1', name: 'Số lượng vai trò (tối thiểu 3)', maxPoints: 4,
          fullDesc: '>=3 vai trò có tên rõ ràng, phân biệt nhau',
          acceptDesc: '3 vai trò nhưng 2 vai trò tương tự nhau',
          failDesc: '<3 vai trò hoặc chỉ ghi tên người',
        ),
        Criterion(
          id: '4.2', name: 'Số lượng nhiệm vụ/giao phẩm (tối thiểu 10)', maxPoints: 6,
          fullDesc: '>=10 nhiệm vụ / giao phẩm / hoạt động, đủ bao quát vòng đời dự án',
          acceptDesc: '7-9 nhiệm vụ',
          failDesc: '<7 nhiệm vụ',
        ),
        Criterion(
          id: '4.3', name: 'Mỗi nhiệm vụ có đúng 1 Responsible và 1 Accountable', maxPoints: 8,
          fullDesc: 'Mỗi hàng đúng 1 R, đúng 1 A; A luôn là người có thẩm quyền quyết định cuối',
          acceptDesc: 'Đúng số lượng R và A nhưng A không phải người ra quyết định',
          failDesc: 'Nhiều R hoặc nhiều A trên cùng một hàng',
        ),
        Criterion(
          id: '4.4', name: 'Phân công C và I hợp lý', maxPoints: 6,
          fullDesc: 'C = người được tham vấn trước khi quyết định; I = người được thông báo sau; không lạm dụng C',
          acceptDesc: 'Có C và I nhưng không phân biệt được sự khác nhau',
          failDesc: 'Bỏ trống C và I hoàn toàn hoặc tất cả đều là C',
        ),
        Criterion(
          id: '4.5', name: 'Vai trò và nhiệm vụ phù hợp ngữ cảnh dự án', maxPoints: 6,
          fullDesc: 'Vai trò và nhiệm vụ tương ứng với thông tin trong đề bài',
          acceptDesc: 'Phù hợp nhưng thiếu một số vai trò quan trọng từ đề bài',
          failDesc: 'Vai trò/nhiệm vụ không liên quan đến đề bài',
        ),
      ],
      commonErrors: [
        'Một nhiệm vụ có nhiều hơn 1 Responsible (R phải là 1 người/vai trò chính)',
        'Lẫn lộn Accountable và Responsible: PM là A cho mọi thứ không có nghĩa PM làm tất cả',
        'Không có hàng nào phân biệt được khi nào dùng C vs I',
        'Nhiệm vụ quá chung: chỉ ghi "Phát triển phần mềm" thay vì chia nhỏ',
      ],
    ),
  ],
);
